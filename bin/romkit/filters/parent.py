from __future__ import annotations

from romkit.filters.base import ExactFilter

# Filter on whether the machine is a clone of another
class CloneFilter(ExactFilter):
    name = 'clones'

    def normalize(self, values: Set) -> Set:
        # Avoid normalization
        return values

    def values(self, machine: Machine) -> set:
        return {machine.parent_name is not None}
