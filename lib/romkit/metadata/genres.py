from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Genre, as identified by the system or community
class GenresMetadata(BaseMetadata):
    name = 'genres'

    def update(self, machine: Machine, genres: List[str]) -> None:
        machine.genres.update(genres)
