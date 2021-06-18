from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on the machine name
class NameFilter(ExactFilter):
    name = 'names'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.name}


# Filter on the machine title
class TitleFilter(ExactFilter):
    name = 'titles'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.title}
