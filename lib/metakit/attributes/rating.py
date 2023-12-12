from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class RatingAttribute(BaseAttribute):
    name = 'rating'

    def validate(self, value: float, validation: ValidationResults) -> None:
        if not(isinstance(value, int) or isinstance(value, float)) or value < 0:
            validation.error(f'rating must be non-negative: {value}')
