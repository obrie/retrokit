from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Machine type categorization (e.g. Games, Applications, Utilities, etc.)
class CategoryAttribute(BaseAttribute):
    metadata_name = 'category'
    rule_name = 'categories'
    data_type = str

    def set(self, machine: Machine, category: str) -> None:
        machine.category = category

    def get(self, machine: Machine) -> Optional[str]:
        return machine.category
