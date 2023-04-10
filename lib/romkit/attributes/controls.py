from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Input control type requirements
class ControlAttribute(BaseAttribute):
    metadata_name = 'controls'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, controls: List[str]) -> None:
        machine.controls = set(controls)

    def get(self, machine: Machine) -> Set[str]:
        return machine.controls
