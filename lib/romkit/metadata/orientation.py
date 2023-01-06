from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# The orientation of the screen
class OrientationMetadata(BaseMetadata):
    name = 'orientation'

    def update(self, machine: Machine, orientation: str) -> None:
        machine.orientation = orientation
