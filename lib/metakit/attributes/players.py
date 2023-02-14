from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class PlayersAttribute(BaseAttribute):
    name = 'players'

    def validate(self, value: int) -> List[str]:
        if not isinstance(value, int) or value < 0:
            return [f'players must be positive integer: {value}']
