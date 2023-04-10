from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Game publisher
class PublisherAttribute(BaseAttribute):
    metadata_name = 'publisher'
    rule_name = 'publishers'
    data_type = str

    def set(self, machine: Machine, publisher: str) -> None:
        machine.publisher = publisher

    def get(self, machine: Machine) -> str:
        return machine.publisher
