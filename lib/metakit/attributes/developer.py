from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class DeveloperAttribute(BaseAttribute):
    name = 'developer'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            logger.error(f'developer not valid: {value}')
