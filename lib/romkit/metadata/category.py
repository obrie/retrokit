from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Machine type categorization (e.g. Games, Applications, Utilities, etc.)
class CategoryMetadata(BaseMetadata):
    name = 'category'

    def update(self, machine: Machine, category: str) -> None:
        machine.category = category
