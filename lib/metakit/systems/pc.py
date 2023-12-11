from __future__ import annotations

import lxml.etree
from collections import defaultdict
from pathlib import PureWindowsPath

from romkit.models.machine import Machine
from metakit.systems.base import BaseSystem

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
        doc = lxml.etree.iterparse(str(romset.dat.download_path.path), tag=('Game'))

        # Map game names to their exodos metadata
        exo_games = {}
        for event, exo_game in doc:
            application_path = exo_game.find('ApplicationPath').text
            if application_path and application_path.startswith('eXo\\'):
                name = PureWindowsPath(application_path).stem
                exo_games[name] = exo_game

        for name in sorted(list(exo_games.keys())):
            metadata = self.database.get(name, Machine.title_from(name))
            if metadata is None:
                continue

            exo_game = exo_games[name]

            # Genres
            genre_tag = exo_game.find('Genre')
            if genre_tag is not None:
                genres = [genre.strip() for genre in genre_tag.text.split(';')]
                if genres:
                    metadata['genres'] = genres

            # Rating
            rating_tag = exo_game.find('CommunityStarRating')
            if rating_tag is not None and rating_tag.text is not None:
                rating = round(float(rating_tag.text), 1)
                if rating:
                    metadata['rating'] = rating

            # Players
            play_mode_tag = exo_game.find('PlayMode')
            if play_mode_tag is not None and play_mode_tag.text is not None:
                play_mode = play_mode_tag.text
                if 'Multiplayer' in play_mode or 'Cooperative' in play_mode:
                    metadata['players'] = 2
                else:
                    metadata['players'] = 1

            # Release Year
            release_date = exo_game.find('ReleaseDate')
            if release_date is not None and release_date.text is not None:
                year = int(release_date.text[0:4])
                if 'year' not in metadata or year <= metadata['year']:
                    metadata['year'] = year

            # Developer
            developer_tag = exo_game.find('Developer')
            if developer_tag is not None and developer_tag.text is not None and developer_tag.text != 'Unknown':
                metadata['developer'] = developer_tag.text

            # Publisher
            publisher_tag = exo_game.find('Publisher')
            if publisher_tag is not None and publisher_tag.text is not None and publisher_tag.text != 'Unknown':
                metadata['publisher'] = publisher_tag.text

            tags = set()

            # Series
            series_tag = exo_game.find('Series')
            if series_tag is not None and series_tag.text is not None:
                all_series = [series.strip() for series in series_tag.text.split(';')]
                series = [series for series in all_series if 'Playlist' not in series]
                if series:
                    metadata['series'] = series

                playlists = [series.replace('Playlist: ', '') for series in all_series if 'Playlist' in series]
                if playlists:
                    tags.update(playlists)

            # Tags
            if tags:
                metadata['tags'] = list(tags)
            else:
                metadata['tags'] = []
