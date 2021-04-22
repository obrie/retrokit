from __future__ import annotations

from romkit.filters.base import ExactFilter

# Filter on the machine name
class NameFilter(ExactFilter):
    name = 'names'

    def values(self, machine: Machine) -> set:
        return {machine.name}


# Filter on the machine title
class TitleFilter(ExactFilter):
    name = 'titles'

    def values(self, machine: Machine) -> set:
        return {machine.title}
