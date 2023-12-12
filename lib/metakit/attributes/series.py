from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class SeriesAttribute(BaseAttribute):
    name = 'series'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            validation.error(f'series must be non-empty string: {value}')
