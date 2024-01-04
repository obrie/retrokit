from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class PublishersAttribute(BaseAttribute):
    name = 'publishers'

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        if not all(publisher and isinstance(publisher, str) for publisher in value):
            validation.error(f'publishers must contain non-empty strings: {value}')

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
