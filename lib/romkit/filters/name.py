from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the machine name
class NameFilter(BaseFilter):
    name = 'names'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.name}


# Filter on the machine title
class TitleFilter(BaseFilter):
    name = 'titles'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.title, machine.disc_title}
