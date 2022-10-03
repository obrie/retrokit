from __future__ import annotations

import logging
import re

# Represents a playlist for combining multiple machines
class Playlist:
    DISC_REGEX = re.compile(r' \(Disc [0-9A-Z]+\)')
    DISC_FULL_REGEX = re.compile(fr'{DISC_REGEX.pattern}.*$')

    def __init__(self, machine: Machine) -> None:
        self.machine = machine
        self._resource = None

    @property
    def name(self) -> str:
        return self.name_from(self.machine.name)

    @classmethod
    def name_from(cls, name: str) -> str:
        return cls.DISC_FULL_REGEX.sub('', name)

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Builds context for formatting dirs/urls
    @property
    def context(self) -> dict:
        return {
            **self._resource_context,
            'playlist_filename': self.resource.target_path.path.name,
        }

    # Builds context for formatting dirs/urls
    @property
    def _resource_context(self) -> dict:
        return {
            'playlist': self.name,
            **self.machine.context,
        }

    # Target destination for installing this playlist
    @property
    def resource(self) -> Resource:
        if not self._resource:
            self._resource = self.romset.resource('playlist', **self._resource_context)
        return self._resource

    # Adds the associated machine to the playlist
    def install(self) -> None:
        logging.info(f'[{self.machine.name}] Installing to playlist {self.name}')
        self.resource.install()

    # Enables the playlist to be accessible to the emulator
    def enable(self, system_dir: SystemDir) -> None:
        system_dir.symlink('playlist', self.resource, **self.context)

    # Removes this playlist permanently from the filesystem
    def delete(self):
        self.resource.target_path.delete()
