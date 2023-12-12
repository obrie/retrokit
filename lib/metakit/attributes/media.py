from __future__ import annotations
from typing import Dict

from metakit.attributes.base import BaseAttribute

class MediaAttribute(BaseAttribute):
    name = 'media'

    VALID_VALUES = {
        'artwork',
        'overlay',
    }

    def validate(self, value: Dict[str, str], validation: ValidationResults) -> None:
        for key, value in value.items():
            if key not in self.VALID_VALUES:
                validation.error(f"media name not valid: {key}")

            if not value:
                validation.error(f"media url is missing for {key}")

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        return self._sort_dict(value)
