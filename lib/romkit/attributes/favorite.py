from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Whether the machine is marked as a favorite
class IsFavoriteAttribute(BaseAttribute):
    rule_name = 'favorite'
    data_type = bool

    def get(self, machine: Machine) -> bool:
        return machine.favorite
