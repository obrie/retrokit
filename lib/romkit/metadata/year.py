from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Year of the release
class YearMetadata(BaseMetadata):
    name = 'year'

    def update(self, machine: Machine, year: int) -> None:
        machine.year = year
