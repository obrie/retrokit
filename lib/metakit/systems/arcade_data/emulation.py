import csv
import os
from typing import List, Optional

from romkit.resources.resource import ResourceTemplate
from metakit.systems.arcade_data.base import ExternalData

# Emulation compatibility ratings as defined by roslof's rpi4 spreadsheet
class EmulationData(ExternalData):
    attribute = 'emulation'
    allow_clone_overrides = True
    resource_template = ResourceTemplate.from_json({
        'source': 'https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/export?format=tsv&gid=0',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/rpi-compatibility.xml',
    })

    # TSV Columns
    COLUMN_ROM = 0
    COLUMN_EMULATOR = 2
    COLUMN_FPS = 3
    COLUMN_VISUALS = 4
    COLUMN_AUDIO = 5
    COLUMN_CONTROLS = 6
    QUALITY_COLUMNS = [COLUMN_FPS, COLUMN_VISUALS, COLUMN_AUDIO, COLUMN_CONTROLS]

    def _load(self) -> None:
        self.values = {}

        resource = self.download()
        with resource.target_path.path.open('r') as f:
            rows = csv.reader(f, delimiter='\t')
            for row in rows:
                if len(row) <= self.COLUMN_CONTROLS:
                    # Not a valid row in the compatibility list
                    return

                name = row[self.COLUMN_ROM]
                emulator = row[self.COLUMN_EMULATOR]
                rating = self._calculate_rating(row)

                self.values[name] = {'emulator': emulator, 'rating': rating}

    # Calculate a "compatibility rating" based on how different parts of the
    # emulation are working.
    # * Significant issues drop in rating quickly
    # * Minor issues have less of an effect
    def _calculate_rating(self, row: List[str]) -> int:
        rating = 5
        for col in self.QUALITY_COLUMNS:
            if row[col] == 'x':
                if col == self.COLUMN_FPS:
                    rating -= 2
                else:
                    rating -= 1
            elif row[col] == '!':
                # Significantly broken features get counted as worse
                rating -= 2

        return rating

    def get_value(self, name, attribute, database):
        if name in self.values:
            return self.values[name]
        elif name in database.romkit.resolved_groups:
            # Source sometimes uses the clone name to refer to the group.
            # Attempt to find that based on the machines that were grouped
            # together.
            machines = database.romkit.find_machines_by_group(name)
            for machine in machines:
                if machine.name in self.values:
                    return self.values[machine.name]
