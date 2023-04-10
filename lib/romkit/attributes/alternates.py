from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Provides alternate machine names to match from the download source
class AlternatesAttribute(BaseAttribute):
    metadata_name = 'alternates'
    data_type = str

    def set(self, machine: Machine, alternates: Dict[str, List[str]]) -> None:
        if machine.name in alternates:
            machine.alt_names = alternates[machine.name]
