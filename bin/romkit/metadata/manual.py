from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv

# Manual availability
# 
# Format: TSV (default)
#  
# Columns:
# * 0 - ROM Name
# * 1 - Manual URL
class ManualMetadata(ExternalMetadata):
    name = 'manual'

    def load(self) -> None:
        self.data = {}
        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                key = row[0]
                url = row[1]

                self.data[key] = url

    def update(self, machine: Machine) -> None:
        if not hasattr(self, 'key'):
            self.key = self.config.get('key', 'title')

        machine_key = getattr(machine, self.key)
        parent_key = getattr(machine, f'parent_{self.key}')

        manual_url = self.data.get(machine.name) or self.data.get(machine.title) or self.data.get(machine.parent_title)
        if manual_url:
            machine.manual_url = manual_url
