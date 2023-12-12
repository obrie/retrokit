from __future__ import annotations

import logging
import os
import shlex
from pathlib import Path

from metakit.attributes.base import BaseAttribute

class KeyAttribute(BaseAttribute):
    name = 'key'
    supports_overrides = False

    ROOT_PATH = Path(os.environ['RETROKIT_HOME'])
    CONFIG_PATHS = [
        'config/systems/{system}/autoport/{group}.cfg',
        'config/systems/{system}/retroarch/{group}.*',
        'config/systems/{system}/retroarch/*/{group}.*',
        'config/systems/{system}/retroarch/commands/{group}.commands',
    ]

    EXTERNAL_PATHS = [
        '.emulationstation/downloaded_media/{system}/manuals/.*/{group} (*'
    ]

    def get(self, key, entry):
        return key

    def validate(self, value: str, validation: ValidationResults) -> None:
        if value not in self.romkit.keys:
            validation.error(f"key not a valid name / disc title / title: {value}")

    # Migrates any references to the group outside the context of the metadata
    # database (such as config files)
    def migrate(self, from_group: str, to_group: str, *args) -> None:
        # Move all config files that are committed to source
        for glob_template in self.CONFIG_PATHS:
            glob = glob_template.format(system=self.romkit.system.name, group=from_group)

            for group_config_path in self.ROOT_PATH.glob(f'**/{glob}'):
                new_path = Path(str(group_config_path).replace(from_group, to_group))
                group_config_path.rename(new_path)
                logging.info(f'[{from_group}] [config] Moved to {new_path}')

        # Print commands for files that are outside the source code
        for glob_template in self.EXTERNAL_PATHS:
            glob = glob_template.format(system=self.romkit.system.name, group=from_group)

            for group_file_path in Path.home().glob(glob):
                new_path = Path(str(group_file_path).replace(from_group, to_group))
                print(f'mv -v {shlex.quote(str(group_file_path))} {shlex.quote(str(new_path))}')
