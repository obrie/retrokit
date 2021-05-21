from __future__ import annotations

from romkit.filters.base import ExactFilter

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

    def match(self, machine: Machine) -> bool:
        return machine.emulator and machine.emulator == machine.romset.system.emulator_set.get(machine)
