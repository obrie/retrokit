from __future__ import annotations

import logging
import re
import shlex

# Represents a playlist for combining multiple machines
class Playlist:
    DISC_REGEX = re.compile(r' \(Disc [0-9A-Z]+\)')

    def __init__(self, machine: Machine) -> None:
        self.machine = machine

    @property
    def name(self) -> str:
        return self.DISC_REGEX.sub('', self.machine.name)

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Builds context for formatting dirs/urls
    @property
    def context(self) -> dict:
        context = {
            'playlist': self.name,
            **self.machine.context,
        }
        context['playlist_filename'] = self.romset.resource('playlist', **context).target_path.path.name
        return context

    # Target destination for installing this playlist
    @property
    def resource(self) -> Resource:
        return self.romset.resource('playlist', **self.context)

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

    # Prints the commands required to remove this playlist from the filesystem
    def purge(self):
        if self.resource.target_path.exists():
            print(f'rm -rf {shlex.quote(str(self.resource.target_path.path))}')
