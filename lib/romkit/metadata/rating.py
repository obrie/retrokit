from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Community-determined rating of the game
class RatingMetadata(BaseMetadata):
    name = 'rating'

    def update(self, machine: Machine, rating: float) -> None:
        machine.rating = rating
