from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Custom (usually system-specific) metadata associated with the machine
class CustomAttribute(BaseAttribute):
    metadata_name = 'custom'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, custom: Dict[str, str]) -> None:
        machine.custom.update(custom)

    def get(self, machine: Machine) -> Set[str]:
        return set(machine.custom.keys())
