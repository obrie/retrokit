from __future__ import annotations

from romkit.filters.base import ExactFilter

# Filter on the orientation
class OrientationFilter(ExactFilter):
    name = 'orientations'

    def values(self, machine: Machine) -> set:
        return {machine.orientation}
