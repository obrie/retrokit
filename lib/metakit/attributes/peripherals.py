from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class PeripheralsAttribute(BaseAttribute):
    name = 'peripherals'

    VALUES = {'link_cable', 'multitap'}

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        for peripheral in value:
            if peripheral not in self.VALUES:
                validation.error(f"peripheral not valid: {peripheral}")

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
