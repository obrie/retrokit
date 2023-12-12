from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class ButtonsAttribute(BaseAttribute):
    name = 'buttons'

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        if all(not(button and isinstance(button, str)) for button in value):
            validation.error(f"button is all blanks: {value}")
            return

        if not value[-1]:
            validation.error(f"button ends with blank: {value}")
