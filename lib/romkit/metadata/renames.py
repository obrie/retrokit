from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Renames machines in order to match the download source
class RenamesMetadata(BaseMetadata):
    name = 'renames'

    def update(self, machine: Machine, renames: Dict[str, str]) -> None:
        if machine.name in renames:
            machine.alt_name = renames[machine.name]
