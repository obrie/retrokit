from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class IdAttribute(BaseAttribute):
    name = 'id'
    set_from_machine = True

    @property
    def required(self) -> bool:
        return self.config['roms']['id'] == 'crc'

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            validation.error(f'id not valid: {value}')

    def get_from_machine(self, machine: Machine, grouped_machines: List[Machine]) -> Optional[str]:
        if self.required:
            return machine.id
