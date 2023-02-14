from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class AgeRatingAttribute(BaseAttribute):
    name = 'age_rating'

    def validate(self, value: str) -> List[str]:
        if not value or not isinstance(value, str):
            return [f'age_rating not valid: {value}']
