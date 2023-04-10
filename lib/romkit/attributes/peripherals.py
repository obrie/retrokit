from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Peripherals supported
class PeripheralsAttribute(BaseAttribute):
    metadata_name = 'peripherals'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, peripherals: List[str]) -> None:
        machine.peripherals = set(peripherals)

    def get(self, machine: Machine) -> Set[str]:
        return machine.peripherals
