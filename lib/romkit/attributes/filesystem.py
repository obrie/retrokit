from __future__ import annotations

from romkit.attributes.base import BaseAttribute
from romkit.models.playlist import Playlist

from pathlib import Path
from typing import Set

# Attribute on the presence of the machine on the filesystem
class FilesystemAttribute(BaseAttribute):
    rule_name = 'filesystem'
    data_type = bool

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)

        self.installed_names = set()

    def configure(self, install_paths: List[str] = [], **kwargs) -> None:
        for path in install_paths:
            for installed_file in Path(path).glob("*"):
                self.installed_names.add(installed_file.stem)

    def get(self, machine: Machine) -> bool:
        candidates = {
            machine.name,
            machine.playlist_name,
            *machine.alt_names,
            *{Playlist.name_from(name) for name in machine.alt_names},
        }

        return self.installed_names.isdisjoint(candidates) > 0
