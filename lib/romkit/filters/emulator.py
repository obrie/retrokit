from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on the emulators to allow
class EmulatorFilter(ExactFilter):
    name = 'emulators'
    apply_to_overrides = True

    def values(self, machine: Machine) -> set:
        return {machine.emulator}

# Filter on the emulator known to be compatible with the machine
class EmulatorCompatibilityFilter(ExactFilter):
    name = 'emulator_compatibility'
    apply_to_overrides = True
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.emulator is not None and ((not machine.romset.emulator) or (machine.emulator == machine.romset.emulator))}

# Filter on rating of the compatibility of the game with the emulator
class EmulatorRatingFilter(ExactFilter):
    name = 'emulator_ratings'
    normalize_values = False

    def values(self, machine: Machine) -> Set[int]:
        return machine.emulator_rating is not None and {machine.emulator_rating} or self.empty
