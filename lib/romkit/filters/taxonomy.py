from __future__ import annotations

from romkit.filters.base import ExactFilter, SubstringFilter

from typing import Set

# Filter on categories (the type of the machine)
class CategoryFilter(SubstringFilter):
    name = 'categories'

    def values(self, machine: Machine) -> Set[str]:
        if machine.category:
            return {machine.category}
        else:
            return self.empty

# Filter on genres
class GenreFilter(SubstringFilter):
    name = 'genres'

    def values(self, machine: Machine) -> Set[str]:
        return machine.genres

# Filter on custom collections
class CollectionFilter(ExactFilter):
    name = 'collections'

    def values(self, machine: Machine) -> Set[str]:
        return machine.collections

# Filter on arbitary tags
class TagFilter(ExactFilter):
    name = 'tags'

    def values(self, machine: Machine) -> Set[str]:
        return machine.tags
