import logging
import os
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

    # Source url to get the disk
    @property
    def url(self):
        return self.machine.build_url('disk', filename=self.name)

    # Target destination for installing this disk
    @property
    def filepath(self):
        return self.machine.build_filepath('disk', filename=self.name)

    # Downloads and installs the disk
    def install(self):
        logging.info(f'[{self.machine.name}] Installing disk {self.name}')
        self.romset.download(self.url, self.filepath)

    # Enables the disk to be accessible to the emulator
    def enable(self, dirname):
        target_filepath = self.machine.build_system_filepath(dirname, 'disk', filename=self.name)
        target_dirname = os.path.dirname(target_filepath)
        Path(os.path.dirname(target_dirname)).mkdir(parents=True, exist_ok=True)

        os.symlink(os.path.dirname(self.filepath), target_dirname, target_is_directory=True)
