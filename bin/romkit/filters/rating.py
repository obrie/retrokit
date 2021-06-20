from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on user ratings
class RatingFilter(ExactFilter):
    name = 'ratings'
    normalize_values = False

    def values(self, machine: Machine) -> Set[int]:
        if machine.rating is not None:
          return {machine.rating}
        else:
          return self.empty
