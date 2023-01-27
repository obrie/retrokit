from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on categories (the type of the machine)
class CategoryFilter(BaseFilter):
    name = 'categories'

    def values(self, machine: Machine) -> Set[str]:
        if machine.category:
            return {machine.category}
        else:
            return self.empty

# Filter on genres
class GenreFilter(BaseFilter):
    name = 'genres'

    def values(self, machine: Machine) -> Set[str]:
        return machine.genres

# Filter on series
class SeriesFilter(BaseFilter):
    name = 'series'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.series}

# Filter on custom collections
class CollectionFilter(BaseFilter):
    name = 'collections'

    def values(self, machine: Machine) -> Set[str]:
        return machine.collections

# Filter on arbitary tags
class TagFilter(BaseFilter):
    name = 'tags'

    def values(self, machine: Machine) -> Set[str]:
        return machine.tags
