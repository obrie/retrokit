from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# The machine's system name (useful when using a common set definition for rules)
class SystemAttribute(BaseAttribute):
    rule_name = 'systems'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.romset.system.name
