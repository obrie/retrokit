from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class CategoryAttribute(BaseAttribute):
    name = 'category'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            validation.error(f'category not valid: {value}')
