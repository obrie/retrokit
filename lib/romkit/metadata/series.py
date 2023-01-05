from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# The series the game belongs to
class SeriesMetadata(BaseMetadata):
    name = 'series'

    def update(self, machine: Machine, series: str) -> None:
        machine.series = series
