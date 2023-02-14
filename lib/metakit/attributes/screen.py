from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class ScreenAttribute(BaseAttribute):
    name = 'screen'

    ORIENTATION_VALUES = {'horizontal', 'vertical'}

    def validate(self, value: dict) -> List[str]:
        if 'screen' in value:
            if value['orientation'] not in self.ORIENTATION_VALUES:
                return [f"screen orientation not valid: {value['orientation']}"]

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        return self._sort_dict(value)
