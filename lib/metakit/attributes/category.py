from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class CategoryAttribute(BaseAttribute):
    name = 'category'

    def validate(self, value: str) -> List[str]:
        if not value or not isinstance(value, str):
            return [f'category not valid: {value}']