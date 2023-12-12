from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class PublisherAttribute(BaseAttribute):
    name = 'publisher'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            validation.error(f'publisher not valid: {value}')
