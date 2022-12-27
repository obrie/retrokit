from __future__ import annotations

from romkit.sorters.base import SubstringSorter

# Sort on whether the machine has the same title as the parent
class ParentTitleSorter(SubstringSorter):
    name = 'parent_title'

    def value(self, machine: Machine) -> bool:
        return str(machine.parent_name is None or machine.parent_title == machine.title)
