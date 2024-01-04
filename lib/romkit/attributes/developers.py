from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Game developers
class DevelopersAttribute(BaseAttribute):
    metadata_name = 'developers'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, developers: List[str]) -> None:
        machine.developers.update(developers)

    def get(self, machine: Machine) -> Set[str]:
        return machine.developers
