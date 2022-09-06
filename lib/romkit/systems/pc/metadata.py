from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import json
import lxml.etree
from pathlib import Path, PureWindowsPath

# Game metadata managed by exodos
# 
# Format: XML
class ExodosMetadata(ExternalMetadata):
    name = 'exodos_data'

    def load(self) -> None:
        self.metadata = {}

        doc = lxml.etree.iterparse(str(self.install_path), tag=('Game'))

        for event, game in doc:
            application_path = game.find('ApplicationPath').text
            if application_path:
                path = PureWindowsPath(application_path)
                name = path.stem

                genre_tag = game.find('Genre')
                if genre_tag is not None:
                    genres = genre_tag.text.split(';')
                else:
                    genres = None

                play_mode_tag = game.find('PlayMode')
                if play_mode_tag is not None and play_mode_tag.text is not None:
                    play_mode = play_mode_tag.text
                    if 'Multiplayer' in play_mode or 'Cooperative' in play_mode:
                        players = 2
                    else:
                        players = 1
                else:
                    players = None

                self.metadata[name] = {
                    'genres': genres,
                    'players': players,
                }

    def update(self, machine: Machine) -> None:
        data = self.metadata.get(machine.name)

        # Genre
        genres = data and data['genres']
        if genres:
            machine.genres.update(genres)

        # Players
        players = data and data['players']
        if players:
            machine.players = players
