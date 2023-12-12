from __future__ import annotations
from typing import Dict

from metakit.attributes.base import BaseAttribute

class CustomAttribute(BaseAttribute):
    name = 'custom'

    def validate(self, value: Dict[str, str], validation: ValidationResults) -> None:
        for key, value in value.items():
            if not key:
                validation.error('keys must be non-empty strings')

            if not value:
                validation.error('values must be non-empty strings')

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        return self._sort_dict(value)
