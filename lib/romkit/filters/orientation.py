from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on the orientation
class OrientationFilter(ExactFilter):
    name = 'orientations'

    def values(self, machine: Machine) -> Set[str]:
        if machine.orientation:
            return {machine.orientation}
        else:
            return self.empty
