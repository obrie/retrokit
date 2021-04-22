from romkit.filters.base import ExactFilter

# Filter on the emulator known to be compatible with the machine
class EmulatorFilter(ExactFilter):
    name = 'emulators'
    apply_to_favorites = True

    def match(self, machine):
        return machine.emulator and machine.emulator == machine.romset.system.emulator_set.get(machine)
