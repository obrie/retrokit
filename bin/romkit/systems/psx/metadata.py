from __future__ import annotations

from romkit.metadata.external import ExternalMetadata
from romkit.models.machine import Machine

import json
from pathlib import Path

# Game metadata managed by Duckstation
# 
# Format: JSON
class DuckstationMetadata(ExternalMetadata):
    name = 'duckstation_data'

    def load(self) -> None:
        self.metadata = {}

        with self.install_path.open() as file:
            data = json.load(file)
            for game in data:
                if 'genre' in game or 'language' in game:
                    self.set_data(game['name'], {
                        'genre': game.get('genre'),
                        'language': game.get('language')
                    })

    def update(self, machine: Machine) -> None:
        machine_data = self.data.get(Machine.normalize(machine.name))
        if machine.parent_name:
            parent_data = self.data.get(Machine.normalize(machine.parent_name))
        else:
            parent_data = None

        # Genre
        genre = machine_data and machine_data['genre'] or parent_data and parent_data['genre']
        if genre:
            machine.genres.add(genre)

        # Language
        language = machine_data and machine_data['language'] or parent_data and parent_data['language']
        if language:
            machine.languages.add(language)
