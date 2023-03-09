from __future__ import annotations
from typing import Dict

from metakit.attributes.base import BaseAttribute

class AlternatesAttribute(BaseAttribute):
    name = 'alternates'

    # Validate:
    # * Non-empty keys and values
    # * Keys are valid rom names
    def validate(self, value: Dict[str, str]) -> List[str]:
        errors = []

        for rom_name, alt_names in value.items():
            if not rom_name or not alt_names:
                errors.append(f'alternate key/value missing: {rom_name} => {alt_names}')

            if rom_name not in self.romkit.names:
                errors.append(f'alternate key not a valid name: {rom_name}')

        return errors

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        sorted_dict = self._sort_dict(value)
        for key in list(sorted_dict.keys()):
            sorted_dict[key] = self._sort_list(sorted_dict[key])

        return sorted_dict

    # Migrates the list of machine keys (name/title/disc) to merge based on the
    # new group being used.
    def migrate(self, from_group: str, to_group: str, value: List[str]) -> None:
        group_machines = self.romkit.find_machines_by_group(to_group)
        group_machine_names = {machine.name for machine in group_machines}

        for rom_name in list(value.keys()):
            if rom_name in self.romkit.names:
                continue

            alt_names = value[rom_name]
            for alt_name in list(alt_names):
                if alt_name in group_machine_names:
                    logging.info(f'[{to_group}] [merge] Removed alternate {alt_name}')
                    alt_names.remove(alt_name)

            if not alt_names:
                delete value[rom_name]
