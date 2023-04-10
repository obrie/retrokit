from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Whether the machine is runnable
class RunnableAttribute(BaseAttribute):
    rule_name = 'runnable'
    data_type = bool

    def get(self, machine: Machine) -> bool:
        return machine.runnable and not machine.is_bios
