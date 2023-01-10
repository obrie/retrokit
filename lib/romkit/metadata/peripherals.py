from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Peripherals supported
class PeripheralsMetadata(BaseMetadata):
    name = 'peripherals'

    def update(self, machine: Machine, peripherals: List[str]) -> None:
        machine.peripherals = set(peripherals)
