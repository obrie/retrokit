from __future__ import annotations

from metakit.frontends.launchbox import LaunchboxDatabase
from metakit.systems.base import BaseSystem
from romkit.models.machine import Machine

from collections import defaultdict
import lxml.etree
import os
import re
from pathlib import Path

class C64Dreams:
    # Metakit database info
    TAG = 'C64 Dreams'
    TAG_BEST_OF = 'C64 Dreams: Best Of'
    CUSTOM_NAME = 'c64dreams-name'

    # C64 Dreams metadata files
    HOME = Path(os.environ['C64_DREAMS_HOME'])
    GAMES_DB_PATH = HOME.joinpath('Data/Platforms/Games.xml')
    PLAYLISTS_PATH = HOME.joinpath('Data/Playlists')

    # Pattern matching
    GAME_NAME_REGEX = re.compile(r'\\Games\\(?P<name>[^\\]+)')
    NORMALIZED_TITLE_REGEX = re.compile(
        r'[^'
            # Alphanumeric
            r'a-z'
            r'0-9'
            # Special characters helpeful for some differentiating some games
            r'\+&'
            # Subscript / superscript
            r'\xc2\xb2-\xc2\xb3'
            r'\xc2\xb9'
            r'\xe2\x81\xb0-\xe2\x82\x9e'
        r']+'
    )

    def __init__(self, metakit_database: metakit.models.database.Database) -> None:
        self.metakit_database = metakit_database
        self.launchbox_database = LaunchboxDatabase(
            path=self.GAMES_DB_PATH,
            name_pattern=self.GAME_NAME_REGEX,
            playlists_dir=self.PLAYLISTS_PATH,
        )

        # Cached properties
        self._indexed_group_table = None

    # Normalizes the given name by removing characters that may differ
    # between a romset machine and C64 Dreams
    @classmethod
    def normalize_title(self, name: str) -> str:
        if not name:
            return

        title = Machine.title_from(name)
        return self.NORMALIZED_TITLE_REGEX.sub('', title.lower())

    # Generates an easily-browsable version of the C64 Dreams database
    def load(self) -> None:
        self.launchbox_database.load()

    # Gets the list of games (and associated metadata) in the C64 Dreams database
    @property
    def games(self) -> List[dict]:
        return self.launchbox_database.games

    # Gets a collection of full list of game names
    @property
    def names(self) -> Set[str]:
        return {game['name'] for game in self.games}

    # Generates an index table for looking up groups based on:
    # * 
    @property
    def indexed_group_table(self) -> Dict[str, str]:
        if self._indexed_group_table is not None:
            return self._indexed_group_table

        self._indexed_group_table = mappings = {}

        for group in self.metakit_database.groups:
            mappings[group] = group
            mappings[self.normalize_title(group)] = group

            # Add merge titles for potentially more identifiers to match
            for merge_name in self.metakit_database.get(group).get('merge', []):
                mappings[merge_name] = group

                normalized_merge_title = self.normalize_title(merge_name)
                if normalized_merge_title not in mappings:
                    mappings[normalized_merge_title] = group

        return mappings

    # Look up the C64 Dreams name currrently configured for the given metakit database key
    def get_configured_name(self, key: str, use_default=True) -> Optional[str]:
        metadata = self.metakit_database.get(key)
        group = metadata.get('group', key)
        if 'group' in metadata:
            metadata = {**self.metakit_database.get(metadata['group']), **metadata}

        # First, confirm that we're actually dealing with a C64 Dreams game
        tags = metadata.get('tags', [])
        if self.TAG not in tags:
            return

        name = metadata.get('custom', {}).get(self.CUSTOM_NAME)
        if not name and use_default:
            name = group

        return name

    # Find metakit groups that match the given C64 Dreams game
    def find_matching_groups(self, id: str) -> List[str]:
        game = self.launchbox_database.find(id)
        dreams_names = [game['name'], game['title'], *game['alternate_names']]

        groups = []
        for normalize in [False, True]:
            for dreams_name in dreams_names:
                if normalize:
                    lookup_name = self.normalize_title(dreams_name)
                else:
                    lookup_name = dreams_name

                group = self.indexed_group_table.get(lookup_name)
                if group and group not in groups:
                    groups.append(group)

        return groups
