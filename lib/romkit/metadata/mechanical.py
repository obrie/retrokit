from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Mechanical requirements
class MechanicalMetadata(BaseMetadata):
    name = 'mechanical'

    def update(self, machine: Machine, mechanical: bool) -> None:
        machine.mechanical = mechanical
