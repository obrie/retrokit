from romkit.models import Disk, ROM, Sample

import logging
import os
import re
from pathlib import Path

# Represents a Game/Device/BIOS
class Machine:
    BASE_NAME_REGEX = re.compile(r'^[^\(]+')
    FLAG_REGEX = re.compile(r'\(([^\)]+)\)')

    def __init__(self, romset, name, description, parent_name, bios_name, sample_name, device_names, controls):
        self.romset = romset
        self.name = name
        self.description = description.lower()
        self.parent_name = parent_name
        self.bios_name = bios_name
        self.sample_name = sample_name
        self.device_names = device_names
        self.controls = controls
        self._local_roms = None

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
        dumped_roms = filter(ROM.is_installable, xml.findall('rom'))
        machine.roms = {ROM.from_xml(machine, rom_xml) for rom_xml in dumped_roms}

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

    # The URL from which the data for this machine will be sourced
    @property
    def source_url(self):
        return self.romset.build.source_url_for(self)

    # The file on the filesystem from which data for this machine will be sourced
    @property
    def source_filepath(self):
        return self.romset.build.source_filepath_for(self)

    # Gets the file path for this machine
    @property
    def filepath(self):
        return self.build_filepath('rom', filename=self.name)

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
        return set(filter(lambda rom: rom.external, self.roms))

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

    # ROMs currently installed locally on the filesystem for this machine
    # 
    # NOTE this is cached, so if you want to pull a fresh list from the filesystem,
    # you need to reset _local_roms.
    @property
    def local_roms(self):
        if not self._local_roms:
            self._local_roms = self.romset.format.find_local_roms(self)

        return self._local_roms

    # Audio sample
    @property
    def sample(self):
        if self.sample_name:
            return Sample(self, self.sample_name)

    # Generates data for use in output actions
    def dump(self):
        return {'name': self.name, 'romset': self.romset.name, 'emulator': self.romset.emulator}

    # Generates a romset-level URL for an asset for this machine
    def build_url(self, asset_name, **args):
        return self.romset.build_url(asset_name, rom=self.name, **args)

    # Generates a romset-level filepath for an asset for this machine
    def build_filepath(self, asset_name, **args):
        return self.romset.build_filepath(asset_name, rom=self.name, **args)

    # Generates a system-level filepath for an asset for this machine
    def build_system_filepath(self, dir_name, asset_name, **args):
        return self.romset.system.build_filepath(dir_name, asset_name, rom=self.name, **args)

    # Determines whether the locally installed set of ROMs is a superset of the ROMs installed
    # just for this machine
    def is_valid(self):
        return not any(self.roms_from_self - self.local_roms)

    # Determines whether the locally installed set of ROMs is equal to the full set of
    # non_merged roms
    def is_valid_nonmerged(self):
        return not any(self.non_merged_roms - self.local_roms)

    # Installs this machine onto the local filesystem
    def install(self):
        # Self
        self.merge(self, self.roms_from_self)

        # Parent
        if self.parent_machine:
            self.merge(self.parent_machine, self.roms_from_parent)

        # BIOS
        if self.bios_machine:
            self.merge(self.bios_machine, self.bios_machine.roms)

        # Devices
        for device_machine in self.device_machines:
            self.merge(device_machine, device_machine.roms)

        # Disks
        for disk in self.disks:
            disk.install()

        # Samples
        if self.sample:
            self.sample.install()

        self.clean()
        self.romset.format.finalize(self)

    # Whether this machine needs to be merged with the given machine
    def needs_merge(self, roms):
        return any(roms - self.local_roms)

    def merge(self, source_machine, roms):
        if not source_machine:
            return

        if self.needs_merge(roms):
            # Download the source
            source_machine.download()

        # Need to check once more in case the source is the same as the target
        if self.needs_merge(roms):
            logging.info(f'[{self.name}] Merging from {source_machine.name}')
            self.romset.format.merge(source_machine, self, roms)
            self._local_roms = None

    # Downloads the machine (if necessary)
    def download(self):
        if not self.is_valid():
            self.romset.download(self.source_url, self.source_filepath, force=True)

    # Removes unnecessary files from the archive, if applicable
    def clean(self):
        extra_roms = self.local_roms - self.non_merged_roms
        for rom in extra_roms:
            logging.info(f'[{self.name}] Deleting unused file {rom.name}')
            rom.remove()

        # Reset rom list
        self._local_roms = None

    # Enables this machine to be visible to the emulator
    def enable(self, dirname):
        logging.info(f'[{self.name}] Enabling in: {dirname}')
        
        # Ensure target directory exists
        target_filepath = self.build_system_filepath(dirname, 'rom', filename=self.name)
        Path(os.path.dirname(target_filepath)).mkdir(parents=True, exist_ok=True)

        os.symlink(self.filepath, target_filepath)

        for disk in self.disks:
            disk.enable(dirname)
