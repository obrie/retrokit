from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Provides a layer on top of predefined parent/clone relationships by grouping together
# additional titles not defined by a romset's dat.
class GroupAttribute(BaseAttribute):
    metadata_name = 'group'
    rule_name = 'groups'
    data_type = str

    def set(self, machine: Machine, group_name: str) -> None:
        machine.group_name = group_name

    def get(self, machine: Machine) -> str:
        return machine.group_name


# Whether the machine has the same title as the group
class GroupIsTitleAttribute(BaseAttribute):
    rule_name = 'group_is_title'
    data_type = bool

    def get(self, machine: Machine) -> bool:
        return machine.group_title == machine.title
