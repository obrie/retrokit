from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Community-determined rating of the game
class RatingAttribute(BaseAttribute):
    metadata_name = 'rating'
    rule_name = 'ratings'
    data_type = float

    def set(self, machine: Machine, rating: float) -> None:
        machine.rating = rating

    def get(self, machine: Machine) -> Set[float]:
      return machine.rating
