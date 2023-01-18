from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on the machine's system name (useful when using a common set definition for filters)
class SystemFilter(ExactFilter):
    name = 'systems'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.romset.system.name}