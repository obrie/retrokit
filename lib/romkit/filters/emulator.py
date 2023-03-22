from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the emulators to allow
class EmulatorFilter(BaseFilter):
    name = 'emulators'
    apply_to_overrides = True

    def values(self, machine: Machine) -> set:
        return {machine.emulator}

# Filter on the emulator known to be compatible with the machine
class EmulatorCompatibilityFilter(BaseFilter):
    name = 'emulator_compatibility'
    apply_to_overrides = True
    normalize_values = False

    def values(self, machine: Machine) -> Set[bool]:
        if machine.emulator is None or not machine.romset.emulators:
            return self.empty
        else:
            return {machine.emulator in machine.romset.emulators}

# Filter on rating of the compatibility of the game with the emulator
class EmulatorRatingFilter(BaseFilter):
    name = 'emulator_ratings'
    normalize_values = False

    def values(self, machine: Machine) -> Set[int]:
        return machine.emulator_rating is not None and {machine.emulator_rating} or self.empty
