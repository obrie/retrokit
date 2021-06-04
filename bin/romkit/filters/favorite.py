from __future__ import annotations

from romkit.filters.base import ExactFilter
from romkit.filters.filter_set import FilterReason

# Filter on whether the machine is marked as a favorite
class FavoriteFilter(ExactFilter):
    name = 'favorites'

    def normalize(self, values: Set) -> Set:
        # Avoid normalization
        return values

    def values(self, machine: Machine) -> set:
        return {machine.favorite}
