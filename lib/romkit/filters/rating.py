from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on user ratings
class RatingFilter(BaseFilter):
    name = 'ratings'
    normalize_values = False

    def values(self, machine: Machine) -> Set[float]:
        if machine.rating is not None:
          return {machine.rating}
        else:
          return self.empty
