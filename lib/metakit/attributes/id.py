from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class IdAttribute(BaseAttribute):
    name = 'id'

    @property
    def required(self) -> bool:
        return self.config['roms']['id'] == 'crc'

    def validate(self, value: str) -> List[str]:
        if not value or not isinstance(value, str):
            return [f'id not valid: {value}']
