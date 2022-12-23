from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Maximum number of players supported by the machine
class PlayersMetadata(BaseMetadata):
    name = 'players'

    def update(self, machine: Machine, players: int) -> None:
        machine.players = players
