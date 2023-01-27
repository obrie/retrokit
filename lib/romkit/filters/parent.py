from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on whether the machine is a clone of another
class CloneFilter(BaseFilter):
    name = 'clones'
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.parent_name is not None}

# Filter on the parent machine name
class ParentNameFilter(BaseFilter):
    name = 'parent_names'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.parent_name or machine.name}


# Filter on the parent machine title
class ParentTitleFilter(BaseFilter):
    name = 'parent_titles'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.parent_title or machine.title, machine.parent_disc_title or machine.disc_title}
