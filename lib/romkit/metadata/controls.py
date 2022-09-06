from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv

# Input control type requirements
# 
# Format: TSV
#  
# Columns:
# * 0 - ROM Name
# * 1 - Input controller types
class ControlsMetadata(ExternalMetadata):
    name = 'controls'

    def load(self) -> None:
        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                name = row[0]
                controls = set(row[1].split(','))
                self.set_data(name, controls)

    def update(self, machine: Machine) -> None:
        controls = self.get_data(machine)
        if controls:
            machine.controls = controls
