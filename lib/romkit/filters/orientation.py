from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the orientation
class OrientationFilter(BaseFilter):
    name = 'orientations'

    def values(self, machine: Machine) -> Set[str]:
        if machine.orientation:
            return {machine.orientation}
        else:
            return self.empty
