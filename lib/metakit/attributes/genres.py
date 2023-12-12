from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class GenresAttribute(BaseAttribute):
    name = 'genres'

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        if not all(genre and isinstance(genre, str) for genre in value):
            validation.error(f"genres must contain non-empty strings: {value}")

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
