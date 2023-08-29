from __future__ import annotations

import logging
from typing import Dict

from metakit.attributes.base import BaseAttribute

class AlternatesAttribute(BaseAttribute):
    name = 'alternates'

    def load(self) -> None:
        self.valid_discovered_names = set()

        # Discover which names are available in the romset archives
        for romset in self.romkit.system.romsets:
            if not romset.discovery:
                continue

            romset.discovery.load()
            self.valid_discovered_names.update(romset.discovery.machine_keys())

    # Validate:
    # * Non-empty keys and values
    # * Keys are valid rom names
    def validate(self, value: Dict[str, str]) -> List[str]:
        errors = []

        for rom_name, alt_names in value.items():
            if rom_name not in self.romkit.names:
                errors.append(f'alternate key not valid: {rom_name}')

            if not alt_names:
                errors.append(f'alternate names missing: {rom_name}')
            else:
                for alt_name in alt_names:
                    if self.valid_discovered_names and alt_name not in self.valid_discovered_names:
                        errors.append(f'alternate name not valid: {alt_name}')

        return errors

    def format(self, value: Dict[str, str]) -> Dict[str, str]:
        sorted_dict = self._sort_dict(value)
        for key in list(sorted_dict.keys()):
            sorted_dict[key] = self._sort_list(sorted_dict[key])

        return sorted_dict

    # Cleans the list of alternate names based on the names currently defined
    # in the system dat and in the discovery source.
    def clean(self, group: str, value: Dict[str, List[str]]) -> None:
        group_machines = self.romkit.find_machines_by_group(group)
        group_machine_names = {machine.name for machine in group_machines}

        for rom_name in list(value.keys()):
            if rom_name in self.valid_discovered_names:
                # Name is valid -- no longer need to track alternates
                del value[rom_name]
                logging.info(f'[{group}] [clean] Removed alternates for {rom_name}')
            else:
                alt_names = value[rom_name]
                for alt_name in list(alt_names):
                    if alt_name in group_machine_names:
                        alt_names.remove(alt_name)
                        logging.info(f'[{group}] [clean] Removed unused alternate {alt_name}')

                if not alt_names:
                    del value[rom_name]
                    logging.info(f'[{group}] [clean] Removed alternates for {rom_name}')
