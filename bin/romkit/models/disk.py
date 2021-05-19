from __future__ import annotations

import logging
from pathlib import Path

# Represents an external disk used by a machine
class Disk:
    # Status when a ROM isn't actually included in the Machine
    STATUS_NO_DUMP = 'nodump'

    def __init__(self, machine: Machine, name: str) -> None:
        self.machine = machine

        # Some DATs include the .chd extension, so we standardize by removing it
        self.name = Path(name).stem

    # Should this disk be installed to the local filesystem?
    @staticmethod
    def is_installable(xml: lxml.etree.ElementBase) -> bool:
        return xml.get('status') != Disk.STATUS_NO_DUMP

    # Builds context for formatting dirs/urls
    @property
    def context(self) -> dict:
        context = {
            'disk': self.name,
            **self.machine.context,
        }
        context['disk_filename'] = self.romset.resource('disk', **context).target_path.path.name
        return context

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Target destination for installing this sample
    @property
    def resource(self) -> Resource:
        return self.romset.resource('disk', **self.context)

    # Downloads and installs the disk
    def install(self) -> None:
        logging.info(f'[{self.machine.name}] Installing disk {self.name}')
        self.resource.install()

    # Enables the disk to be accessible to the emulator
    def enable(self, system_dir: SystemDir) -> None:
        system_dir.symlink('disk', self.resource.target_path.path, **self.context)

    # Removes this disk from the filesystem
    def purge(self):
        if self.resource.target_path.exists():
            print(f'rm -rf "{self.resource.target_path.path}"')
