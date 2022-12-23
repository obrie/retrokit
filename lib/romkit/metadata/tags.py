from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Community-determined rating of the game
class TagsMetadata(BaseMetadata):
    name = 'tags'

    def update(self, machine: Machine, tags: List[str]) -> None:
        machine.tags.update(tags)
