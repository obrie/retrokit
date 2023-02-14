from __future__ import annotations
from typing import Dict

from metakit.attributes.base import BaseAttribute

class RenamesAttribute(BaseAttribute):
    name = 'renames'

    # Validate:
    # * Non-empty keys and values
    # * Values are valid rom names
    def validate(self, value: Dict[str, str]) -> List[str]:
        errors = []

        for key, value in value.items():
            if not key or not value:
                errors.append(f'rename from/to missing: {key} => {value}')

            if key not in self.romkit.names:
                errors.append(f'rename from not a valid name: {key}')

        return errors

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        return self._sort_dict(value)
