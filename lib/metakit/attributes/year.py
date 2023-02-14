from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class YearAttribute(BaseAttribute):
    name = 'year'

    def validate(self, value: str) -> List[str]:
        if not value or not isinstance(value, int):
            return [f'year not valid: {value}']
