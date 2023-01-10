from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on the supported peripherlas
class PeripheralFilter(ExactFilter):
    name = 'peripherals'

    def values(self, machine: Machine) -> Set[str]:
        return machine.peripherals
