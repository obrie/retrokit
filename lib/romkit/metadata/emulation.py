from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Compatibility layer for ensuring the appropriate emulator is used
class EmulationMetadata(BaseMetadata):
    name = 'emulation'

    def update(self, machine: Machine, emulation: dict) -> None:
        if 'emulator' in emulation:
            machine.emulator = emulation['emulator']

        if 'rating' in emulation:
            machine.emulator_rating = emulation['rating']
