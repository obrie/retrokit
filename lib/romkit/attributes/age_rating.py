from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Game age rating (ESRB, PEGI, or SS)
class AgeRatingAttribute(BaseAttribute):
    metadata_name = 'age_rating'
    rule_name = 'age_ratings'
    data_type = str

    def set(self, machine: Machine, age_rating: str) -> None:
        machine.age_rating = age_rating

    def get(self, machine: Machine) -> Optional[str]:
        return machine.age_rating
