from __future__ import annotations
from typing import Dict

from metakit.attributes.base import BaseAttribute

class CustomAttribute(BaseAttribute):
    name = 'custom'

    def validate(self, value: Dict[str, str]) -> List[str]:
        errors = []

        for key, value in value.items():
            if not key:
                errors.append('keys must be non-empty strings')

            if not value:
                errors.append('values must be non-empty strings')

        return errors

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        return self._sort_dict(value)
