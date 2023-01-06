from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Input button names (i.e. what each button does in the game)
class ButtonsMetadata(BaseMetadata):
    name = 'buttons'

    def update(self, machine: Machine, buttons: List[str]) -> None:
        machine.buttons = buttons
