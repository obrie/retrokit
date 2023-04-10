from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Input button names (i.e. what each button does in the game)
class ButtonsAttribute(BaseAttribute):
    metadata_name = 'buttons'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, buttons: List[str]) -> None:
        machine.buttons = buttons

    def get(self, machine: Machine) -> List[str]:
        return machine.buttons
