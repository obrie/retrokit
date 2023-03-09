from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Provides alternate machine names to match from the download source
class AlternatesMetadata(BaseMetadata):
    name = 'alternates'

    def update(self, machine: Machine, alternates: Dict[str, List[str]]) -> None:
        if machine.name in alternates:
            machine.alt_names = alternates[machine.name]
