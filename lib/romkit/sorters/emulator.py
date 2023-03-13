from __future__ import annotations

from romkit.sorters.base import BaseSorter

# Sort on whether the machine's target emulator is the same as the emulator associated with the romset
class IsEmulatorCompatibleSorter(BaseSorter):
    name = 'is_emulator_compatible'

    def value(self, machine: Machine) -> str:
        return str(machine.emulator is not None and machine.emulator in machine.romset.emulators)
