from __future__ import annotations

from romkit.sorters.base import SubstringSorter

# Sort on presence of a romset
class RomsetSorter(SubstringSorter):
    name = 'romsets'

    def value(self, machine: Machine) -> str:
        return machine.romset.name
