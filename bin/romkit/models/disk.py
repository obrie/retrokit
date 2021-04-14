import logging
from pathlib import Path

# Represents an external disk used by a machine
class Disk:
    # Status when a ROM isn't actually included in the Machine
    STATUS_NO_DUMP = 'nodump'

    def __init__(self, machine, name):
        self.machine = machine

        # Some DATs include the .chd extension, so we standardize by removing it
        self.name = Path(name).stem

    # Should this disk be installed to the local filesystem?
    @staticmethod
    def is_installable(xml):
        return xml.get('status') != Disk.STATUS_NO_DUMP

    @property
    def romset(self):
        return self.machine.romset

    # Target destination for installing this sample
    @property
    def resource(self):
        return self.romset.resource('disk', **self._context)

    # Downloads and installs the disk
    def install(self):
        logging.info(f'[{self.machine.name}] Installing disk {self.name}')
        self.resource.install()

    # Enables the disk to be accessible to the emulator
    def enable(self, system_dir):
        system_dir.symlink('disk', self.resource.target_path.path, **self._context)

    # Builds context for formatting dirs/urls
    @property
    def _context(self):
        return {'machine': self.machine.name, 'disk': self.name}