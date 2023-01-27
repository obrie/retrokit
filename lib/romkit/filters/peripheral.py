from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the supported peripherlas
class PeripheralFilter(BaseFilter):
    name = 'peripherals'

    def values(self, machine: Machine) -> Set[str]:
        return machine.peripherals
