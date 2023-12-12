from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class AgeRatingAttribute(BaseAttribute):
    name = 'age_rating'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            validation.error(f'age_rating not valid: {value}')
