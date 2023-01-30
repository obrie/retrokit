from __future__ import annotations

from romkit.sorters.base import BaseSorter

# Sort on associated romset
class ROMSetSorter(BaseSorter):
    name = 'romsets'
    exact = True

    def value(self, machine: Machine) -> str:
        return machine.romset.name
