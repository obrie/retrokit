from __future__ import annotations

from romkit.filters.base import BaseFilter
from romkit.filters.filter_set import FilterReason

from typing import Set

# Filter on whether the machine is marked as a favorite
class FavoriteFilter(BaseFilter):
    name = 'favorites'
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.favorite}
