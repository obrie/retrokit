from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Assigned collections
class CollectionAttribute(BaseAttribute):
    rule_name = 'collections'
    data_type = str

    def get(self, machine: Machine) -> Set[str]:
        return machine.collections
