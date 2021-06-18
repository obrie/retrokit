from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv

# Compatibility layer for ensuring the appropriate emulator is used
# 
# Format: TSV (default)
#  
# Columns:
# * 0 - ROM Name
# * 1 - Emulator Name
class EmulatorMetadata(ExternalMetadata):
    name = 'emulator'

    def load(self) -> None:
        # Grab the configuration
        column_rom = self.config.get('column_rom', 0)
        column_emulator = self.config.get('column_emulator', 1)
        delimiter = self.config.get('delimiter', '\t')
        self.emulators = self.config.get('overrides', {})

        # User may have just specified overrides -- in that case, there's
        # nothing left to load/process
        if not self.install_path:
            return

        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter=delimiter)
            for row in rows:
                # Make sure this is a row that actually defines the emulator
                if len(row) <= column_rom or len(row) <= column_emulator:
                    continue

                rom_key = row[column_rom]
                emulator = row[column_emulator]

                # Check that we have an emulator and we haven't processed this ROM
                # already
                if rom_key not in self.emulators and emulator and emulator != '':
                    self.emulators[rom_key] = emulator

    def update(self, machine: Machine) -> None:
        if not hasattr(self, 'key'):
            self.key = self.config.get('key', 'name')

        machine_key = getattr(machine, self.key)
        parent_key = getattr(machine, f'parent_{self.key}')

        machine.emulator = self.emulators.get(machine_key) or self.emulators.get(parent_key)
