from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on whether the machine is a BIOS
class BIOSFilter(BaseFilter):
    name = 'bios'
    normalize_values = False

    def values(self, machine: Machine) -> Set[str]:
        return {machine.is_bios}

# Filter on whether the machine is runnable
class RunnableFilter(BaseFilter):
    name = 'runnable'
    normalize_values = False

    def values(self, machine: Machine) -> Set[str]:
        return {machine.runnable and not machine.is_bios}
