from __future__ import annotations

from romkit.sorters.base import BaseSorter

# Sort on whether the machine is a parent or clone
class IsParentSorter(BaseSorter):
    name = 'is_parent'

    def value(self, machine: Machine) -> str:
        return str(machine.parent_name is None)
