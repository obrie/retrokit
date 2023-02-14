from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class PublisherAttribute(BaseAttribute):
    name = 'publisher'

    def validate(self, value: str) -> List[str]:
        if not value or not isinstance(value, str):
            return [f'publisher not valid: {value}']
