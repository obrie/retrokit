from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class DevelopersAttribute(BaseAttribute):
    name = 'developers'

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        if not all(developer and isinstance(developer, str) for developer in value):
            validation.error(f'developers must contain non-empty strings: {value}')

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
