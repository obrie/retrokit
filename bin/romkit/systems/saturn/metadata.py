from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv

# Compatibility rating of the game with the lr-yabasanshiro emulator
# 
# Format: TSV
# 
# Columns:
# * ROM Title
# * Rating
class EmulatorRatingMetadata(ExternalMetadata):
    name = 'emulator_rating'

    def load(self):
        self.emulator_ratings = {}

        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                title = row[0]
                rating = row[1]
                self.emulator_ratings[title] = int(rating)

    def update(self, machine: Machine) -> None:
        machine.emulator_rating = self.emulator_ratings.get(machine.title) or self.emulator_ratings.get(machine.parent_title)
