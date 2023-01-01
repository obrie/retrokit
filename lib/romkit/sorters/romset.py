from __future__ import annotations

from romkit.sorters.base import BaseSorter

# Sort on associated romset
class RomsetSorter(BaseSorter):
    name = 'romsets'

    def value(self, machine: Machine) -> str:
        return machine.romset.name
