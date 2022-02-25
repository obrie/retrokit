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
        self.column_rom = self.config.get('column_rom', 0)
        self.column_emulator = self.config.get('column_emulator', 1)
        self.column_rating = self.config.get('column_rating', 2)
        self.delimiter = self.config.get('delimiter', '\t')

        for rom_key, emulator in self.config.get('overrides', {}).items():
            self.set_data(rom_key, {'emulator': emulator, 'rating': None})

        # User may have just specified overrides -- in that case, there's
        # nothing left to load/process
        if not self.install_path:
            return

        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter=self.delimiter)
            for row in rows:
                rom_data = self.read_row(row)
                if not rom_data:
                    continue

                rom_key = rom_data.pop('rom')
                if rom_key not in self.data:
                    self.set_data(rom_key, rom_data)
                else:
                    existing = self.data[rom_key]
                    if not existing['emulator'] and rom_data['emulator']:
                        existing['emulator'] = rom_data['emulator']

                    if existing['rating'] is None and rom_data['rating'] is not None:
                        existing['rating'] = rom_data['rating']

    def read_row(self, row: List[str]) -> dict:
        if len(row) <= max(filter(None, [self.column_rom, self.column_emulator, self.column_rating])):
            return

        return {
            'rom': row[self.column_rom],
            'emulator': row[self.column_emulator] if self.column_emulator else None,
            'rating': int(row[self.column_rating]) if self.column_rating else None
        }

    def update(self, machine: Machine) -> None:
        emulator_data = self.get_data(machine)
        if emulator_data:
            if emulator_data['emulator']:
                machine.emulator = emulator_data['emulator']

            if emulator_data['rating']:
                machine.emulator_rating = emulator_data['rating']
