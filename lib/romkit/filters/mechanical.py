from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the mechanical requirements
class MechanicalFilter(BaseFilter):
    name = 'mechanical'
    normalize_values = False

    def values(self, machine: Machine) -> Set[str]:
        if machine.is_mechanical is not None:
            return {machine.is_mechanical}
        else:
            return self.empty
