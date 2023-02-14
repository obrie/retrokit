from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class MechanicalAttribute(BaseAttribute):
    name = 'mechanical'

    VALUES = {True, False}

    def validate(self, value: str) -> List[str]:
        if value not in self.VALUES:
            return [f'mechanical not valid: {value}']
