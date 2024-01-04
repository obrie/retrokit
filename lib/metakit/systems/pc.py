from __future__ import annotations

import re
from collections import defaultdict

from romkit.models.machine import Machine
from romkit.util.dict_utils import slice_only
from metakit.systems.base import BaseSystem
from metakit.frontends.launchbox import LaunchboxDatabase

class PCSystem(BaseSystem):
    name = 'pc'

    # We handle groups a little differently for PC than other systems due to
    # the number of titles that are duplicated over the years.
    # 
    # When a title was only released for a single year, the group is based
    # on the title (no year included).  When there are releases for the same
    # title, then we always include the year in the group.
    @property
    def target_groups(self) -> Set[str]:
        self.romkit.load()

        # Identify groups to ignore
        ignored_groups = set()

        # Count how many times we see this title
        title_counts = defaultdict(lambda: 0)
        for machine in self.romkit.machines.all():
            metadata = self.romkit.system.metadata.get(machine)
            if 'merge' in metadata:
                ignored_groups.update(metadata['merge'])

            title_counts[machine.title] = title_counts[machine.title] + 1

        # Identify the target list of groups
        groups = set()
        for machine in self.romkit.machines.all():
            if machine.title in ignored_groups or machine.name in ignored_groups:
                continue

            if title_counts[machine.title] == 1:
                groups.add(machine.title)
            else:
                groups.add(machine.name)

        return groups

    # Skip
    def update_dats(self) -> None:
        pass

    # Update metadata from the exodos database
    def update_metadata(self) -> None:
        romset = self.romkit.romsets[0]

        # Load the launchbox database
        launchbox_db = LaunchboxDatabase(
            path=romset.dat.download_path.path,
            name_pattern=re.compile('(?P<name>[^\\\\]+)\\.bat'),
        )
        launchbox_db.load()

        for game in launchbox_db.games:
            metadata = self.database.get(game['name'], Machine.title_from(game['name']))
            if metadata is None:
                continue

            # Merge in metadata
            # * Since we own the series / tag values, they get reset if not detected from the launchbox database
            metadata.update({'series': [], 'tags': []})
            metadata.update(slice_only(game, {'genres', 'rating', 'players', 'year', 'developers', 'publishers', 'series', 'tags'}))
