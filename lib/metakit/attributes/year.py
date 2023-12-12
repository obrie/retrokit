from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class YearAttribute(BaseAttribute):
    name = 'year'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, int):
            validation.error(f'year not valid: {value}')
