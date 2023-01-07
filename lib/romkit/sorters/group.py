from __future__ import annotations

from romkit.sorters.base import BaseSorter

# Sort on whether the machine has the same title as the group
class IsGroupTitleSorter(BaseSorter):
    name = 'is_group_title'

    def value(self, machine: Machine) -> str:
        return str(machine.group_title == machine.title)
