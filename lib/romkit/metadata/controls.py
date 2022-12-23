from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Input control type requirements
class ControlsMetadata(BaseMetadata):
    name = 'controls'

    def update(self, machine: Machine, controls: List[str]) -> None:
        machine.controls = set(controls)
