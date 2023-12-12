from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class PlayersAttribute(BaseAttribute):
    name = 'players'

    def validate(self, value: int, validation: ValidationResults) -> None:
        if not isinstance(value, int) or value < 0:
            validation.error(f'players must be positive integer: {value}')
