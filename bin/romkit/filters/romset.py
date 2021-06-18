from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on the machine's romset name
class ROMSetFilter(ExactFilter):
    name = 'romsets'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.romset.name}
