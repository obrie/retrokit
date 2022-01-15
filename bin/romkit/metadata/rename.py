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
            self.renames = json.load(file)

    def update(self, machine: Machine) -> None:
        if machine.name in self.renames:
            machine.alt_machine_name = self.renames[machine.name]
