from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Year of the release
class YearAttribute(BaseAttribute):
    metadata_name = 'year'
    rule_name = 'years'
    data_type = int

    def set(self, machine: Machine, year: int) -> None:
        machine.year = year

    def get(self, machine: Machine) -> Optional[int]:
        return machine.year
