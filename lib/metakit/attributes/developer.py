from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class DeveloperAttribute(BaseAttribute):
    name = 'developer'

    def validate(self, value: str) -> List[str]:
        if not value or not isinstance(value, str):
            return [f'developer not valid: {value}']
