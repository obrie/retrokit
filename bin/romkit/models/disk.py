from __future__ import annotations

import logging
from pathlib import Path

# Represents an external disk used by a machine
class Disk:
    # Status when a ROM isn't actually included in the Machine
    STATUS_NO_DUMP = 'nodump'

    def __init__(self, machine: Machine, name: str, sha1: Optional[str] = None) -> None:
        self.machine = machine

        # Some DATs include the .chd extension, so we standardize by removing it
        self.name = Path(name).stem

        self.sha1 = sha1
        self.id = sha1

        self._resource = None

    # Should this disk be installed to the local filesystem?
    @staticmethod
    def is_installable(xml: lxml.etree.ElementBase) -> bool:
        return xml.get('status') != Disk.STATUS_NO_DUMP

    # Builds context for formatting dirs/urls, including resource filenames
    @property
    def context(self) -> dict:
        return {
            **self.__resource_context,
            'disk_filename': self.resource.target_path.path.name,
        }

    # Builds context for formatting dirs/urls
    @property
    def __resource_context(self) -> dict:
        context = {
            'disk': self.name,
            **self.machine.context,
        }
        if self.sha1:
            context['sha1'] = self.sha1

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Target destination for installing this sample
    @property
    def resource(self) -> Resource:
        if not self._resource:
            self._resource = self.romset.resource('disk', **self.__resource_context)
        return self._resource

    # Downloads and installs the disk
    def install(self) -> None:
        logging.info(f'[{self.machine.name}] Installing disk {self.name}')
        self.resource.check_xref()
        self.resource.install()
        self.resource.create_xref()

    # Enables the disk to be accessible to the emulator
    def enable(self, system_dir: SystemDir) -> None:
        system_dir.symlink('disk', self.resource, **self.context)

    # Equality based on Unique ID
    def __eq__(self, other) -> bool:
        if isinstance(other, Disk):
            return self.id == other.id
        return False

    # Hash based on Unique ID
    def __hash__(self) -> str:
        return hash(self.id)
