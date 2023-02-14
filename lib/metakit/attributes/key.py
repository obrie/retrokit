from __future__ import annotations

import logging
import os
from pathlib import Path

from metakit.attributes.base import BaseAttribute

class KeyAttribute(BaseAttribute):
    name = 'key'
    supports_overrides = False

    ROOT_PATH = Path(os.environ['RETROKIT_HOME'])
    CONFIG_PATHS = [
        'config/systems/*/autoport/{group}.cfg',
        'config/systems/*/retroarch/{group}.*',
        'config/systems/*/retroarch/*/{group}.*',
        'config/systems/daphne/retroarch/commands/{group}.commands',
    ]

    def value_from(self, key, entry):
        return key

    def validate(self, value: str) -> List[str]:
        if value not in self.romkit.names and value not in self.romkit.titles and value not in self.romkit.disc_titles:
            return [f"key not a valid name / disc title / title: {value}"]

    # Migrates any references to the group outside the context of the metadata
    # database (such as config files)
    def migrate(self, from_group: str, to_group: str, *args) -> None:
        for glob_template in self.CONFIG_PATHS:
            glob = glob_template.format(group=from_group)

            for group_config_path in self.ROOT_PATH.glob(f'**/{glob}'):
                new_path = Path(str(group_config_path).replace(from_group, to_group))
                group_config_path.rename(new_path)
                logging.info(f'[{from_group}] [config] Moved to {new_path}')
