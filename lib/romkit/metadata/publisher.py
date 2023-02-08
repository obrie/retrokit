from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Game publisher
class PublisherMetadata(BaseMetadata):
    name = 'publisher'

    def update(self, machine: Machine, publisher: str) -> None:
        machine.publisher = publisher
