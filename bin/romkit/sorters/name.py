from __future__ import annotations

from romkit.sorters.base import OrderingSorter

# Sort on name length
class LengthSorter(OrderingSorter):
    name = 'length'

    def value(self, machine: Machine) -> int:
        return len(machine.name)


# Sort on name, alphabetically
class NameSorter(OrderingSorter):
    name = 'name'

    def value(self, machine: Machine) -> str:
        return machine.name
