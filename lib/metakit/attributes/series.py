from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class SeriesAttribute(BaseAttribute):
    name = 'series'

    def validate(self, series: str, validation: ValidationResults) -> None:
        if not all(name and isinstance(name, str) for name in series):
            validation.error(f'series must contain non-empty strings: {series}')

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
