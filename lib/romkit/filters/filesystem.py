from __future__ import annotations

from romkit.filters.base import BaseFilter

from pathlib import Path
from typing import Set

# Filter on the presence of the machine on the filesystem
class FilesystemFilter(BaseFilter):
    name = 'filesystem'
    normalize_values = False

    def load(self) -> None:
        self.installed_names = set()
        for system_dir in self.config['roms']['dirs']:
            for installed_file in Path(system_dir['path']).glob("*"):
                self.installed_names.add(installed_file.stem)

    def values(self, machine: Machine) -> Set[bool]:
        return {machine.name in self.installed_names or machine.playlist_name in self.installed_names}
