from __future__ import annotations

from romkit.filters.base import BaseFilter

from pathlib import Path
from typing import Set

# Filter on the presence of the machine on the filesystem
class FilesystemFilter(BaseFilter):
    name = 'filesystem'
    normalize_values = False

    def load(self) -> None:
        self.installed_names = set()
        for system_dir in self.config['roms']['dirs']:
            for installed_file in Path(system_dir['path']).glob("*"):
                self.installed_names.add(installed_file.stem)

    def values(self, machine: Machine) -> Set[bool]:
        candidates = {
            machine.name,
            machine.playlist_name,
            *machine.alt_names,
            *{Playlist.name_from(name) for name in machine.alt_names},
        }

        return {self.installed_names.isdisjoint(candidates) > 0}
