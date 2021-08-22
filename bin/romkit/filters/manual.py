from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on whether the machine has a manual
class ManualFilter(ExactFilter):
    name = 'manuals'
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.manual_url is not None}
