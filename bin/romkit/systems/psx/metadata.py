from __future__ import annotations

from romkit.metadata.external import ExternalMetadata
from romkit.models.machine import Machine

import json
import re
from pathlib import Path

# Game metadata managed by Duckstation
# 
# Format: JSON
class DuckstationMetadata(ExternalMetadata):
    name = 'duckstation_data'

    GENRE_REPLACE_REGEX = re.compile(r'\.+$')

    def load(self) -> None:
        self.metadata = {}

        with self.install_path.open() as file:
            data = json.load(file)
            for game in data:
                if 'genre' in game or 'language' in game or 'maxPlayers' in game:
                    name = game['name']
                    title = Machine.title_from(name)

                    # Pre-existing shared metadata betweeen regional games
                    shared_metadata = self.data.get(title) or {}

                    language = game.get('language')
                    players = game.get('maxPlayers')
                    genre = game.get('genre')

                    # Update players / genre shared metadata between regional games
                    if players and (not shared_metadata.get('players') or shared_metadata['players'] < players):
                        shared_metadata['players'] = players

                    if genre and (not shared_metadata.get('genre')):
                        genre = self.GENRE_REPLACE_REGEX.sub('', genre)
                        shared_metadata['genre'] = genre

                    # Region-specific metadata
                    game_metadata = {}
                    if language:
                        game_metadata['language'] = language

                    self.set_data(name, game_metadata)
                    self.set_data(title, shared_metadata)

    def update(self, machine: Machine) -> None:
        # Prioritize (lowest to highest):
        # * Parent Title
        # * Parent Name
        # * Title
        # * Name
        data = {
            **self.data.get(Machine.normalize(machine.title), {}),
            **self.data.get(Machine.normalize(machine.name), {}),
        }
        if machine.parent_name:
            data = {
                **self.data.get(Machine.normalize(machine.parent_title), {}),
                **self.data.get(Machine.normalize(machine.parent_name), {}),
                **data,
            }

        # Genre
        genre = data.get('genre')
        if genre:
            # Prefer Duckstation genres over scraped genres
            machine.genres.clear()
            machine.genres.add(genre)

        # Language
        language = data.get('language')
        if language:
            machine.languages.add(language)

        # Num. Players (override only if Duckstation thinks more are supported)
        players = data.get('players')
        if players and (not machine.players or machine.players < players):
            machine.players = players
