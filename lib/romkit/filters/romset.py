from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the machine's romset name
class ROMSetFilter(BaseFilter):
    name = 'romsets'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.romset.name}
