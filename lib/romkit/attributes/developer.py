from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Game developer
class DeveloperAttribute(BaseAttribute):
    metadata_name = 'developer'
    rule_name = 'developers'
    data_type = str

    def set(self, machine: Machine, developer: str) -> None:
        machine.developer = developer

    def get(self, machine: Machine) -> Optional[str]:
        return machine.developer
