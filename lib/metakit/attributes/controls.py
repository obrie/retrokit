from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class ControlsAttribute(BaseAttribute):
    name = 'controls'

    VALID_VALUES = {
        'dial',
        'doublejoy',
        'gambling',
        'hanafuda',
        'joy',
        'keyboard',
        'keypad',
        'lightgun',
        'mahjong',
        'mouse',
        'only_buttons',
        'paddle',
        'pedal',
        'pointer',
        'positional',
        'stick',
        'trackball',
    }

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        for control in value:
            if control not in self.VALID_VALUES:
                validation.error(f'control not valid: {control}')

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
