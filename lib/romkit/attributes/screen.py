from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Attribute related to the screen
class ScreenAttribute(BaseAttribute):
    metadata_name = 'screen'
    data_type = dict

    def set(self, machine: Machine, screen: Dict[str, str]) -> None:
        if 'orientation' in screen:
            machine.orientation = screen['orientation']


# Screen orientation
class OrientationAttribute(BaseAttribute):
    rule_name = 'orientations'
    data_type = str

    def get(self, machine: Machine) -> Optional[str]:
        return machine.orientation
