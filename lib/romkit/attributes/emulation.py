from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Compatibility layer for ensuring the appropriate emulator is used
class EmulationAttribute(BaseAttribute):
    metadata_name = 'emulation'
    data_type = dict

    def set(self, machine: Machine, emulation: Dict[str, Any]) -> None:
        if 'emulator' in emulation:
            machine.emulator = emulation['emulator']

        if 'rating' in emulation:
            machine.emulator_rating = emulation['rating']

# Emulator names
class EmulatorAttribute(BaseAttribute):
    rule_name = 'emulators'
    data_type = str
    apply_to_overrides = True

    def get(self, machine: Machine) -> Optional[str]:
        return machine.emulator


# Whether the assigned emulator is compatible with the assigned romset
class EmulatorCompatibilityAttribute(BaseAttribute):
    rule_name = 'emulator_compatibility'
    apply_to_overrides = True
    data_type = bool

    def get(self, machine: Machine) -> Optional[bool]:
        if machine.emulator is None or not machine.romset.emulators:
            return None
        else:
            return machine.emulator in machine.romset.emulators


# Emulator performance rating
class EmulatorRatingAttribute(BaseAttribute):
    rule_name = 'emulator_ratings'
    data_type = bool

    def get(self, machine: Machine) -> Optional[int]:
        return machine.emulator_rating
