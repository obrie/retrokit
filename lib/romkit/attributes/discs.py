from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Number of discs in the machine's playlist
class DiscsAttribute(BaseAttribute):
    metadata_name = 'discs'
    rule_name = metadata_name
    data_type = int

    def set(self, machine: Machine, discs: int) -> None:
        machine.discs = discs

    def get(self, machine: Machine) -> int:
        return machine.discs
