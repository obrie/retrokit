from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# The series the game belongs to
class SeriesAttribute(BaseAttribute):
    metadata_name = 'series'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, series: str) -> None:
        machine.series = series

    def get(self, machine: Machine) -> Optional[str]:
        return machine.series
