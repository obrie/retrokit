from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# The machine's romset name
class ROMSetAttribute(BaseAttribute):
    rule_name = 'romsets'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.romset.name
