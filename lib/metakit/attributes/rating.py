from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class RatingAttribute(BaseAttribute):
    name = 'rating'

    def validate(self, value: float) -> List[str]:
        if not(isinstance(value, int) or isinstance(value, float)) or value < 0:
            return [f'rating must be non-negative: {value}']
