from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class MechanicalAttribute(BaseAttribute):
    name = 'mechanical'

    VALUES = {True, False}

    def validate(self, value: str, validation: ValidationResults) -> None:
        if value not in self.VALUES:
            validation.error(f'mechanical not valid: {value}')
