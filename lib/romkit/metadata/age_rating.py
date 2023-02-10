from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Game age rating (ESRB, PEGI, or SS)
class AgeRatingMetadata(BaseMetadata):
    name = 'age_rating'

    def update(self, machine: Machine, age_rating: str) -> None:
        machine.age_rating = age_rating
