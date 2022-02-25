from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import json

# Renames machines in order to match the download source
# 
# Format: JSON
class RenameMetadata(ExternalMetadata):
    name = 'rename'

    def load(self) -> None:
        with self.install_path.open() as file:
            self.data = json.load(file)

    def update(self, machine: Machine) -> None:
        if machine.name in self.data:
            machine.alt_name = self.data[machine.name]
