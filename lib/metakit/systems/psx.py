from __future__ import annotations

import json
import os
import re

from romkit.models.machine import Machine
from romkit.resources.resource import ResourceTemplate
from metakit.systems.base import BaseSystem

class PSXSystem(BaseSystem):
    name = 'psx'

    GAMEDB_RESOURCE = ResourceTemplate.from_json({
        'source': 'https://github.com/stenzek/duckstation/raw/master/data/resources/database/gamedb.json',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/psx/gamedb.json',
    }).render()
    GENRE_REPLACE_REGEX = re.compile(r'\.+$')

    # Caches external data used by the system, forcing it to be re-downloaded if
    # requested.
    def cache_external_data(self, refresh: bool = False) -> None:
        self.GAMEDB_RESOURCE.install(force=refresh)

    # Update metadata from the exodos database
    def update_metadata(self) -> None:
        super().update_metadata()

        self.cache_external_data()

        with self.GAMEDB_RESOURCE.target_path.path.open('r') as f:
            gamedb = json.load(f)

        lookup_table = self.database.indexed_table

        for gamedb_data in gamedb:
            if 'name' not in gamedb_data:
                continue

            # Use the lookup table to translate gamedb names to names in our database
            name = gamedb_data['name']
            title = Machine.title_from(name)
            key = lookup_table.get(Machine.normalize(title))
            if not key:
                continue

            metadata = self.database.get(key)

            # Prioritize most # of players identified
            players = gamedb_data.get('maxPlayers')
            if players and (not metadata.get('players') or metadata['players'] < players):
                metadata['players'] = players

            # Prioritize more specific genres (approximated by length)
            genre = gamedb_data.get('genre')
            if genre and (not metadata.get('genres') or len(metadata['genres'][0]) < len(genre)):
                genre = self.GENRE_REPLACE_REGEX.sub('', genre)
                metadata['genres'] = [genre]

            # Prioritize older years
            release_date = gamedb_data.get('releaseDate')
            if release_date:
                year = int(release_date[0:4])
                if 'year' not in metadata or year <= metadata['year']:
                    metadata['year'] = year

                    # Set the developer / publisher when we're dealing with the earliest
                    # release
                    developer = gamedb_data.get('developer')
                    if developer:
                        metadata['developers'] = [developer]

                    publisher = gamedb_data.get('publisher')
                    if publisher:
                        metadata['publishers'] = [publisher]
