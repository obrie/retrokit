from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on whether the machine is a clone of another
class CloneFilter(ExactFilter):
    name = 'clones'
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.parent_name is not None}
