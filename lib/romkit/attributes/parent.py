from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# The parent machine name
class ParentNameAttribute(BaseAttribute):
    rule_name = 'parent_names'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.parent_name or machine.name


# The parent machine title
class ParentTitleAttribute(BaseAttribute):
    rule_name = 'parent_titles'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.parent_title or machine.title


# The parent machine disc title
class ParentDiscTitleAttribute(BaseAttribute):
    rule_name = 'parent_disc_titles'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.parent_disc_title or machine.disc_title


# Whether the machine is a parent or clone
class IsParentAttribute(BaseAttribute):
    rule_name = 'is_parent'
    data_type = bool

    def get(self, machine: Machine) -> bool:
        return machine.parent_name is None
