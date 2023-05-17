from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Custom labels associated with the machine
class TagsAttribute(BaseAttribute):
    metadata_name = 'tags'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, tags: List[str]) -> None:
        machine.tags.update(tags)

    def get(self, machine: Machine) -> Set[str]:
        return machine.tags
