from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class ButtonsAttribute(BaseAttribute):
    name = 'buttons'

    def validate(self, value: List[str]) -> List[str]:
        if all(not(button and isinstance(button, str)) for button in value):
            return [f"button is all blanks: {value}"]

        if not value[-1]:
            return [f"button ends with blank: {value}"]
