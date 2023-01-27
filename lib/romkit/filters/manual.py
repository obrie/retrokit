from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on whether the machine has a manual
class ManualFilter(BaseFilter):
    name = 'manuals'
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.manual is not None}
