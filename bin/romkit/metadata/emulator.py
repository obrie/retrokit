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
        column_rating = self.config.get('column_rating', 2)
        delimiter = self.config.get('delimiter', '\t')

        self.data = {}
        for rom_key, emulator in self.config.get('overrides', {}).items():
            self.data[rom_key] = {'emulator': emulator}

        # User may have just specified overrides -- in that case, there's
        # nothing left to load/process
        if not self.install_path:
            return

        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter=delimiter)
            for row in rows:
                # Make sure this is a row that actually defines the emulator
                if len(row) <= max(filter(None, [column_rom, column_emulator, column_rating])):
                    continue

                rom_key = row[column_rom]
                emulator = row[column_emulator] if column_emulator else None
                rating = row[column_rating] if column_rating else None

                if rom_key not in self.data:
                    self.data[rom_key] = {'emulator': None, 'rating': None}

                # Only set metadata if it's not already present
                rom_data = self.data[rom_key]
                if not rom_data['emulator'] and emulator and emulator != '':
                    rom_data['emulator'] = emulator

                if not rom_data['rating'] and rating is not None and rating != '':
                    rom_data['rating'] = int(rating)

    def update(self, machine: Machine) -> None:
        if not hasattr(self, 'key'):
            self.key = self.config.get('key', 'title')

        machine_key = getattr(machine, self.key)
        parent_key = getattr(machine, f'parent_{self.key}')

        emulator_data = self.data.get(machine_key) or self.data.get(parent_key)
        if emulator_data:
            if emulator_data['emulator']:
                machine.emulator = emulator_data['emulator']

            if emulator_data['rating']:
                machine.emulator_rating = emulator_data['rating']
