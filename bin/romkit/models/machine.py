from romkit.models import Disk, File, Sample

import logging
import re
from pathlib import Path

# Represents a Game/Device/BIOS
class Machine:
    BASE_NAME_REGEX = re.compile(r'^[^\(]+')
    FLAG_REGEX = re.compile(r'\(([^\)]+)\)')

    def __init__(self,
        romset,
        name,
        description='',
        parent_name=None,
        bios_name=None,
        sample_name=None,
        device_names=set(),
        controls=set(),
    ):
        self.romset = romset
        self.name = name
        self.description = description.lower()
        self.parent_name = parent_name
        self.bios_name = bios_name
        self.sample_name = sample_name
        self.device_names = device_names
        self.controls = controls
        self.disks = set()
        self.roms = set()

    # Whether this machine is installable
    @staticmethod
    def is_installable(xml):
        return xml.get('ismechanical') != 'yes' and xml.find('rom') is not None

    @staticmethod
    def from_xml(romset, xml):
        # Devices
        device_names = {device.get('name') for device in xml.findall('device_ref')}
        
        # Controls
        controls = {control.get('name') for control in xml.findall('control')}

        parent_name = xml.get('cloneof')
        bios_name = xml.get('romof')
        if bios_name == parent_name:
            bios_name = None

        machine = Machine(
            romset,
            xml.get('name'),
            xml.find('description').text,
            parent_name,
            bios_name,
            xml.get('sampleof'),
            device_names,
            controls,
        )

        # Disks
        dumped_disks = filter(Disk.is_installable, xml.findall('disk'))
        machine.disks = {Disk(machine, disk.get('name')) for disk in dumped_disks}

        # ROMs
        dumped_roms = filter(File.is_installable, xml.findall('rom'))
        machine.roms = {
            File.from_xml(rom_xml, file_identifier=machine.resource.file_identifier)
            for rom_xml in dumped_roms
        }

        return machine

    # Tracks this machine so that it can be referenced later from the romset
    def track(self):
        self.romset.track(self)

    @property
    def is_clone(self):
        return self.parent_name is not None

    # Machine name (no extension, no flags)
    @property
    def base_name(self):
        return self.BASE_NAME_REGEX.search(self.name).group().strip()

    # Flags from description
    @property
    def flags(self):
        return set(self.FLAG_REGEX.findall(self.description))

    # Flags, isolated
    @property
    def flags_str(self):
        flag_start = self.description.find('(')
        if flag_start >= 0:
            return self.description[flag_start:]
        else:
            return ''

    # Target destination for installing this sample
    @property
    def resource(self):
        return self.romset.resource('machine', machine=self.name, parent=(self.parent_name or self.name))

    # Parent machine, if applicable
    @property
    def parent_machine(self):
        if self.parent_name:
            return self.romset.machine(self.parent_name)

    # BIOS machine, if applicable
    @property
    def bios_machine(self):
        if self.bios_name:
            return self.romset.machine(self.bios_name)

    # Devices that are required to run this machine
    @property
    def device_machines(self):
        machines = []
        for device_name in self.device_names:
            machine = self.romset.machine(device_name)
            if machine:
                machines.append(machine)

        return machines

    @property
    def dependent_machine_names(self):
        names = {self.name}
        names.update(self.device_names)
        if self.parent_name:
            names.add(self.parent_name)
        if self.bios_name:
            names.add(self.bios_name)

        return names

    @property
    def dependent_machines(self):
        machines = [self]
        machines.extend(self.device_machines)
        if self.bios_machine:
            machines.append(self.bios_machine)

        return machines

    # ROMs installed from the parent
    @property
    def roms_from_parent(self):
        if self.parent_machine:
            return self.parent_machine.roms & self.roms
        else:
            return set()

    # ROMs installed directly from this machine
    @property
    def roms_from_self(self):
        return self.roms - self.roms_from_parent

    # All ROMs expected to be in the non-merged build (includes parent, bios, and devices)
    @property
    def non_merged_roms(self):
        all_roms = set()
        for machine in self.dependent_machines:
            all_roms.update(machine.roms)

        return all_roms

    # Audio sample
    @property
    def sample(self):
        if self.sample_name:
            return Sample(self, self.sample_name)

    # Generates data for use in output actions
    def dump(self):
        return {'name': self.name, 'romset': self.romset.name, 'emulator': self.romset.emulator}

    # Generates a system-level filepath for an asset for this machine
    def build_system_filepath(self, dir_name, resource_name, **args):
        return self.romset.system.build_filepath(dir_name, resource_name, machine=self.name, **args)

    # Determines whether the locally installed set of ROMs is a superset of the ROMs installed
    # just for this machine
    # def is_valid(self):
    #     return self.resource.contains(self.roms_from_self)

    # Determines whether the locally installed set of ROMs is equal to the full set of
    # non_merged roms
    def is_valid_nonmerged(self):
        return self.resource.contains(self.non_merged_roms)

    # Installs this machine onto the local filesystem
    def install(self):
        # Self
        self.install_from(self, self.roms_from_self)

        # Parent
        if self.parent_machine:
            self.install_from(self.parent_machine, self.roms_from_parent)

        # BIOS
        if self.bios_machine:
            self.install_from(self.bios_machine, self.bios_machine.roms)

        # Devices
        for device_machine in self.device_machines:
            self.install_from(device_machine, device_machine.roms)

        # Disks
        for disk in self.disks:
            disk.install()

        # Samples
        if self.sample:
            self.sample.install()

    def install_from(self, source_machine, roms):
        if not source_machine:
            return

        if self.resource.contains(roms):
            logging.info(f'[{self.name}] Already installed {source_machine.name}')
        else:
            # Re-download the source machine if it's missing files
            if not source_machine.resource.download_path.contains(self.roms_from_self):
                source_machine.resource.download(force=True)

            logging.info(f'[{self.name}] Installing from {source_machine.name}')
            self.resource.install(source_resource=source_machine.resource, files=roms, force=True)

    # Removes unnecessary files from the archive, if applicable
    def clean(self):
        # Clean the resource
        self.resource.clean(self.non_merged_roms)

    # Enables this machine to be visible to the emulator
    def enable(self, dirname):
        logging.info(f'[{self.name}] Enabling in: {dirname}')
        
        self.resource.symlink(self.build_system_filepath(dirname, 'machine'))

        for disk in self.disks:
            disk.enable(dirname)
