from __future__ import annotations

from romkit.filters.base import SubstringFilter

# Filter on categories (redump dats typicaly)
class CategoryFilter(SubstringFilter):
    name = 'categories'

    def values(self, machine: Machine) -> set:
        return {machine.category}
