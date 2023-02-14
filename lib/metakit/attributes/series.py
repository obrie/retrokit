from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class SeriesAttribute(BaseAttribute):
    name = 'series'

    def validate(self, value: str) -> bool:
        if not value or not isinstance(value, str):
            return [f'series must be non-empty string: {value}']
