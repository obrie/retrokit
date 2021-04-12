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
        return self.romset.resource('disk', disk=self.name)

    # Downloads and installs the disk
    def install(self):
        logging.info(f'[{self.machine.name}] Installing disk {self.name}')
        self.resource.install()

    # Enables the disk to be accessible to the emulator
    def enable(self, dirname):
        target_filepath = self.machine.build_system_filepath(dirname, 'disk', disk=self.name)
        target_dirname = Path(target_filepath).parent

        source_dirname = Path(self.filepath).parent
        
        Path(target_dirname).parent.mkdir(parents=True, exist_ok=True)
        Path(target_dirname).symlink_to(source_dirname, target_is_directory=True)
