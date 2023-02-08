from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Game developer
class DeveloperMetadata(BaseMetadata):
    name = 'developer'

    def update(self, machine: Machine, developer: str) -> None:
        machine.developer = developer
