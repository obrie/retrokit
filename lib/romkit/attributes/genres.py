from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Genre, as identified by the system or community
class GenresAttribute(BaseAttribute):
    metadata_name = 'genres'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, genres: List[str]) -> None:
        machine.genres.update(genres)

    def get(self, machine: Machine) -> Set[str]:
        return machine.genres
