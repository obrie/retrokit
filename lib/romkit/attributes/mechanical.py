from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Mechanical requirements
class MechanicalAttribute(BaseAttribute):
    metadata_name = 'mechanical'
    rule_name = metadata_name
    data_type = bool

    def set(self, machine: Machine, mechanical: bool) -> None:
        machine.mechanical = mechanical

    def get(self, machine: Machine) -> bool:
        return machine.is_mechanical
