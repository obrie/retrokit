from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class TagsAttribute(BaseAttribute):
    name = 'tags'

    def validate(self, value: List[str]) -> List[str]:
        if not all(tag and isinstance(tag, str) for tag in value):
            return [f'tags must contain non-empty strings: {value}']

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)