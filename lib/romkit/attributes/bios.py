from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Whether the machine is a BIOS
class BIOSAttribute(BaseAttribute):
    rule_name = 'bios'
    data_type = bool

    def get(self, machine: Machine) -> bool:
        return machine.is_bios
