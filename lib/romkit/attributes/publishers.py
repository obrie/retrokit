from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Game publisher
class PublishersAttribute(BaseAttribute):
    metadata_name = 'publishers'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, publishers: List[str]) -> None:
        machine.publishers.update(publishers)

    def get(self, machine: Machine) -> Set[str]:
        return machine.publishers
