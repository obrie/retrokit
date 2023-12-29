from __future__ import annotations

from metakit.systems.base import BaseSystem
from metakit.systems.c64_data.c64_dreams import C64Dreams
from romkit.models.machine import Machine

import sys

class C64System(BaseSystem):
    name = 'c64'

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)

        self.c64_dreams = C64Dreams(metakit_database=self.database)

    def validate(self) -> ValidationResults:
        validation = super().validate()

        self.c64_dreams.load()

        # Check for mis-mapped c64 dreams names
        for group in self.database.groups:
            dreams_name = self.c64_dreams.get_configured_name(group)
            if dreams_name and dreams_name not in self.c64_dreams.names:
                validation.error(f'{C64Dreams.CUSTOM_NAME} not valid: {dreams_name}', scope=group)

        # Check for c64 dreams names used more than once
        dreams_names = set()
        for group in self.database.groups:
            dreams_name = self.c64_dreams.get_configured_name(group)
            if dreams_name and dreams_name in dreams_names:
                validation.error(f'{C64Dreams.CUSTOM_NAME} already in use: {dreams_name}', scope=group)
            else:
                dreams_names.add(dreams_name)

        # Track which dreams names are associated with which group currently
        dreams_name_to_group = {}
        for group in self.database.groups:
            dreams_name = self.c64_dreams.get_configured_name(group)
            if dreams_name:
                dreams_name_to_group[dreams_name] = group

        # Check for potential clones that aren't merged
        for game in self.c64_dreams.games:
            groups = self.c64_dreams.find_matching_groups(game['id'])

            # Find other groups that are already mapped to this game name
            existing_group = dreams_name_to_group.get(game['name'])
            if existing_group and existing_group not in groups:
                groups.append(existing_group)

            if len(groups) > 1:
                validation.warning(f'Potential clone(s): {groups[1:]}', scope=groups[0])

        return validation

    def save(self) -> None:
        self.c64_dreams.load()

        # Remove c64dreams-name tags where the name matches the group
        # (since that's inferred and doesn't need to be explicit)
        for key in self.database.keys:
            dreams_name = self.c64_dreams.get_configured_name(key, use_default=False)
            metadata = self.database.get(key)
            if dreams_name == key:
                del metadata['custom'][C64Dreams.CUSTOM_NAME]

        super().save()

    # Update metadata from the C64 Dreams database
    def update_metadata(self) -> None:
        super().update_metadata()

        self.c64_dreams.load()

        # Prioritize association with C64 Dreams names based on year, name
        games = sorted(self.c64_dreams.games, key=lambda game: (game.get('year', sys.maxsize), game['name']))

        for game in games:
            groups = self.c64_dreams.find_matching_groups(game['id'])
            if len(groups) != 1:
                continue

            # Get the corresponding metakit data
            group = groups[0]
            metadata = self.database.get(group)

            # Ensure C64 Dreams tag is set (so we identify it as part of the collection)
            tags = metadata.get('tags', [])
            if C64Dreams.TAG not in tags:
                tags.append(C64Dreams.TAG)
                metadata['tags'] = tags

            # Ensure the C64 Dreams game name is set.
            #
            # *Note* We'll only override it if the existing association is invalid.
            existing_dreams_name = self.c64_dreams.get_configured_name(group)
            if existing_dreams_name not in self.c64_dreams.names:
                custom = metadata.get('custom', {})
                custom[C64Dreams.CUSTOM_NAME] = game['name']
                metadata['custom'] = custom

            # Add playlists as tags
            for playlist in game['playlists']:
                playlist = playlist.replace('C64 Dreams ', 'C64 Dreams: ')

                # Add original playlist name as-is
                metadata['tags'].append(playlist)

                # Add aggregate playlist name (e.g. exclude Volume info)
                if ' - ' in playlist:
                    metadata['tags'].append(playlist.split(' - ')[0])
