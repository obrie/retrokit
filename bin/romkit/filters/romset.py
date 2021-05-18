from __future__ import annotations

from romkit.filters.base import ExactFilter

# Filter on the machine's romset name
class ROMSetFilter(ExactFilter):
    name = 'romsets'

    def values(self, machine: Machine) -> set:
        return {machine.romset.name}
