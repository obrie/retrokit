from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Maximum number of players supported by the machine
class PlayersAttribute(BaseAttribute):
    metadata_name = 'players'
    rule_name = metadata_name
    data_type = int

    def set(self, machine: Machine, players: int) -> None:
        machine.players = players

    def get(self, machine: Machine) -> int:
        return machine.players
