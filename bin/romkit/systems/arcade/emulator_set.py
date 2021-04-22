from romkit.models import EmulatorSet

import csv

class ArcadeEmulatorSet(EmulatorSet):
    # TSV Columns
    COLUMN_ROM = 0
    COLUMN_EMULATOR = 2
    COLUMN_FPS = 5
    COLUMN_VISUALS = 6
    COLUMN_AUDIO = 7
    COLUMN_CONTROLS = 8
    QUALITY_COLUMNS = [COLUMN_FPS, COLUMN_VISUALS, COLUMN_AUDIO, COLUMN_CONTROLS]

    def load(self) -> None:
        with self.path.open() as file:
            rows = csv.reader(file, delimiter=self.delimiter)
            for row in rows:
                if len(row) <= self.COLUMN_CONTROLS:
                    # Not a valid row in the compatibility list
                    continue

                rom = row[self.COLUMN_ROM]
                emulator = row[self.COLUMN_EMULATOR]

                if rom not in self.emulators and not any(row[col] == 'x' or row[col] == '!' for col in self.QUALITY_COLUMNS):
                    self.emulators[rom] = emulator
