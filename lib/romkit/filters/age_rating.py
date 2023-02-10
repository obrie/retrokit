from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the age rating
class AgeRatingFilter(BaseFilter):
    name = 'age_ratings'

    def values(self, machine: Machine) -> Set[str]:
        if machine.age_rating:
            return {machine.age_rating}
        else:
            return self.empty
