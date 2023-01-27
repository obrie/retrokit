from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on whether the machine is a BIOS
class BIOSFilter(ExactFilter):
    name = 'bios'
    normalize_values = False

    def values(self, machine: Machine) -> Set[str]:
        return {machine.is_bios}

# Filter on whether the machine is runnable
class RunnableFilter(ExactFilter):
    name = 'runnable'
    normalize_values = False

    def values(self, machine: Machine) -> Set[str]:
        return {machine.runnable and not machine.is_bios}
