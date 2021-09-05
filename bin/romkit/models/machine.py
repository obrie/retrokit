from __future__ import annotations

from romkit.filters.filter_set import FilterReason
from romkit.models.disk import Disk
from romkit.models.file import File
from romkit.models.sample import Sample

import logging
import re
from pathlib import Path
from typing import Dict, List, Optional, Set

# Represents a Game/Device/BIOS
class Machine:
    TITLE_REGEX = re.compile(r'^[^\(]+')
    DISC_REGEX = re.compile(r'\(Disc [0-9A-Z]+\)')
    FLAG_REGEX = re.compile(r'\(([^\)]+)\)')

    def __init__(self,
        romset: ROMSet,
        name: str,

        # Internal metadata
        description: str = '',
        orientation: str = 'horizontal',
        category: Optional[str] = None,
        sourcefile: Optional[str] = None,
        controls: Set[str] = None,

        # File data
        parent_name: Optional[str] = None,
        bios_name: Optional[str] = None,
        sample_name: Optional[str] = None,
        device_names: Set[str] = None,
        roms: Set[File] = None,
        disks: Set[Disk] = None,

        # External metadata
        genres: Set[str] = None,
        collections: Set[str] = None,
        languages: Set[str] = None,
        rating: Optional[int] = None,
        emulator_rating: Optional[int] = None,
        manual: Optional[dict] = None,

        # Additional context to include when rendering resource paths
        custom_context: dict = None,
    ) -> None:
        self.romset = romset
        self.name = name

        # Internal metadata
        self.description = description
        self.orientation = orientation
        self.category = category
        self.sourcefile = sourcefile
        self.controls = controls or set()

        # File data
        self.parent_name = parent_name
        self.bios_name = bios_name
        self.sample_name = sample_name
        self.device_names = device_names or set()
        self.roms = roms or set()
        self.disks = disks or set()

        # External attributes
        self.genres = genres or set()
        self.collections = collections or set()
        self.languages = languages or set()
        self.rating = rating
        self.emulator_rating = emulator_rating
        self.manual = manual

        # Automatic defaults
        self.emulator = romset.emulator
        self.favorite = False
        self.custom_context = custom_context or {}

    # Whether this machine is installable
    @staticmethod
    def is_installable(xml: lxml.etree.ElementBase) -> bool:
        return xml.get('ismechanical') != 'yes' and xml.find('rom') is not None

    @classmethod
    def from_xml(cls, romset: ROMSet, xml: lxml.etree.ElementBase) -> Machine:
        # Devices
        device_names = {device.get('name') for device in xml.findall('device_ref')}
        
        # Controls
        controls = {control.get('name') for control in xml.findall('control')}

        # Orientation
        if xml.findall('video'):
            orientation = xml.findall('video')[0].get('orientation')
        else:
            orientation = 'horizontal'

        # Parent / BIOS
        parent_name = xml.get('cloneof')
        bios_name = xml.get('romof')
        if bios_name == parent_name:
            bios_name = None

        # Sample
        sample_name = xml.get('sampleof')
        if not sample_name and xml.findall('sample'):
            # In older dat files, sampleof wasn't included in the parent.
            # We fall back to checking if there are any <sample /> children
            # and assume the sample archive is the same name as this machine.
            sample_name = xml.get('name')

        category = xml.find('category')
        if category is not None:
            category = category.text

        machine = cls(
            romset,
            xml.get('name'),
            description=xml.find('description').text,
            category=category,
            orientation=orientation,
            parent_name=parent_name,
            bios_name=bios_name,
            sample_name=sample_name,
            device_names=device_names,
            controls=controls,
            sourcefile=xml.get('sourcefile'),
        )

        # Disks
        dumped_disks = filter(Disk.is_installable, xml.findall('disk'))
        machine.disks = {Disk(machine, disk.get('name')) for disk in dumped_disks}

        # ROMs
        dumped_roms = filter(File.is_installable, xml.findall('rom'))
        machine.roms = {
            File.from_xml(rom_xml, file_identifier=romset.resource_templates['machine'].file_identifier)
            for rom_xml in dumped_roms
        }

        return machine

    # Tracks this machine so that it can be referenced later from the romset
    def track(self) -> None:
        self.romset.track(self)

    # Builds context for formatting dirs/urls
    @property
    def context(self) -> dict:
        context = {
            'machine': self.name,
            'machine_sourcefile': self.sourcefile or self.name,
            'parent': (self.parent_name or self.name),
            **self.custom_context,
        }
        context['machine_filename'] = self.romset.resource('machine', **context).target_path.path.name
        return context

    @property
    def is_clone(self) -> bool:
        return self.parent_name is not None

    # Machine title (no extension, no flags), e.g. Chrono Cross
    @property
    def title(self) -> str:
        return self.title_from(self.name)

    # Machine title (no extension, no flags except disc number), e.g. Chrono Cross (Disc 1)
    @property
    def disc_title(self) -> str:
        return self.title_from(self.name, disc=True)

    # Parent machine title (no extension, no flags except for disc name)
    @property
    def parent_title(self) -> Optional[str]:
        return self.parent_name and self.title_from(self.parent_name)

    # Parent machine title (no extension, no flags except for disc name)
    @property
    def parent_disc_title(self) -> Optional[str]:
        return self.parent_name and self.title_from(self.parent_name, disc=True)

    # Builds a title from the given name
    @classmethod
    def title_from(cls, name: str, disc: bool = False) -> str:
        title = cls.TITLE_REGEX.search(name).group().strip()

        if disc:
            disc_match = cls.DISC_REGEX.search(name)
            if disc_match:
                title = f'{title} {disc_match.group().replace("0", "")}'

        return title

    # Flags from description
    @property
    def flags(self) -> Set[str]:
        return set(self.FLAG_REGEX.findall(self.description))

    # Flags, isolated
    @property
    def flags_str(self) -> str:
        flag_start = self.description.find('(')
        if flag_start >= 0:
            return self.description[flag_start:]
        else:
            return ''

    # Estimated filesize in bytes
    @property
    def filesize(self) -> int:
        return sum(map(lambda file: file.size, self.non_merged_roms))

    # Primary rom in the machine.  This is either going to be the *only*
    # rom or a cue that represents multiple rom files.
    @property
    def primary_rom(self) -> Optional[File]:
        if len(self.non_merged_roms) == 1:
            # Only one rom in the machine -- that's the primary one
            return next(iter(self.non_merged_roms))
        elif len(self.non_merged_roms) > 1:
            # Multiple roms -- see if there's a cue file
            cue_file = next(filter(lambda rom: '.cue' in rom.name, self.non_merged_roms), None)
            if cue_file:
                return cue_file

            # Pick the largest file as a last resort
            return sorted(self.non_merged_roms, key=lambda file: file.size)[-1]

    # Target destination for installing this sample
    @property
    def resource(self) -> Resource:
        return self.romset.resource('machine', **self.context)

    # Parent machine, if applicable
    @property
    def parent_machine(self) -> Optional[Machine]:
        if self.parent_name:
            return self.romset.machine(self.parent_name)

    # BIOS machine, if applicable
    @property
    def bios_machine(self) -> Optional[Machine]:
        if self.bios_name:
            return self.romset.machine(self.bios_name)

    # Devices that are required to run this machine
    @property
    def device_machines(self) -> List[Machine]:
        machines = []
        for device_name in self.device_names:
            machine = self.romset.machine(device_name)
            if machine:
                machines.append(machine)

        return machines

    # The names of machines, including this one, that are required for
    # this to run (includes devices, parent, and bios)
    @property
    def dependent_machine_names(self) -> Set[str]:
        names = {self.name}
        names.update(self.device_names)
        if self.parent_name:
            names.add(self.parent_name)
        if self.bios_name:
            names.add(self.bios_name)

        return names

    # ROMs installed from the parent
    # 
    # Note that this assumes ROMs have either the same CRC or the
    # same name.  If using "name" as the file_identifier but the
    # parent ROM has a different name, this will be broken.  We could
    # utilize the @merge property on ROMs to fix this, but at the
    # moment there's no need.
    # 
    # TODO: This is wrong -- we need to listen to the @merge property
    @property
    def roms_from_parent(self) -> Set[File]:
        if self.parent_machine:
            return self.parent_machine.roms & self.roms
        else:
            return set()

    # ROMs installed directly from this machine
    @property
    def roms_from_self(self) -> Set[File]:
        self_roms = self.roms - self.roms_from_parent
        if self.bios_machine:
            self_roms -= self.bios_machine.roms

        return self_roms

    # All ROMs expected to be in the non-merged build (includes parent, bios, and devices)
    @property
    def non_merged_roms(self) -> Set[File]:
        # Define the machines containing the lists of roms required
        # for a non-merged archive
        machines = [self]
        machines.extend(self.device_machines)
        if self.bios_machine:
            machines.append(self.bios_machine)

        # Build up the full set of RMOs required
        all_roms = set()
        for machine in machines:
            all_roms.update(machine.roms)

        return all_roms

    # Audio sample
    @property
    def sample(self) -> Optional[Sample]:
        if self.sample_name:
            return Sample(self, self.sample_name)

    # Generates data for use in output actions
    def dump(self) -> Dict[str, str]:
        data = {
            'system': self.romset.system.name,
            'romset': self.romset.name,

            # Taxonomy
            'name': self.name,
            'disc': self.disc_title,
            'title': self.title,
            'category': self.category,

            # ROM info
            'path': str(self.resource.target_path.path),
            'filesize': self.filesize,
            'description': self.description,
            'orientation': self.orientation,

            # User overrides
            'favorite': self.favorite,

            # External metadata
            'genres': list(self.genres),
            'collections': list(self.collections),
            'languages': list(self.languages),
            'rating': self.rating,
            'emulator': self.emulator,
            'emulator_rating': self.emulator_rating,
            'manual': self.manual,
        }

        primary_rom = self.primary_rom
        if primary_rom:
            data['rom'] = {
                'name': primary_rom.name,
                'crc': primary_rom.crc and primary_rom.crc.upper(),
            }

        if self.parent_name:
            data['parent'] = {
                'name': self.parent_name,
                'disc': self.parent_disc_title,
                'title': self.parent_title
            }

        return data

    # Determines whether the locally installed set of ROMs is equal to the full set of
    # non_merged roms
    def is_valid_nonmerged(self) -> bool:
        return self.resource.contains(self.non_merged_roms)

    # Installs this machine onto the local filesystem
    def install(self) -> None:
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

    # Installs the roms from the given source machine
    def install_from(self, machine: Machine, roms: Set[File]) -> None:
        if not machine:
            return

        if self.resource.contains(roms):
            logging.info(f'[{self.name}] Already installed {machine.name}')
        else:
            # Re-download the source machine if it's missing files
            if not machine.resource.download_path.contains(roms):
                logging.info(f'[{self.name}] Downloading {machine.name}')
                machine.resource.download(force=True)

            logging.info(f'[{self.name}] Installing from {machine.name}')
            self.resource.install(machine.resource, files=roms, force=True)

    # Removes unnecessary files from the archive, if applicable
    def clean(self) -> None:
        # Clean the resource
        self.resource.clean(self.non_merged_roms)

    # Enables this machine to be visible to the emulator
    def enable(self, target_dir: SystemDir):
        logging.info(f'[{self.name}] Enabling in: {target_dir.path}')
        
        target_dir.symlink('machine', self.resource.target_path.path, **self.context)

        for disk in self.disks:
            disk.enable(target_dir)

    # Removes this machine from the filesystem
    def purge(self):
        if self.resource.target_path.exists():
            print(f'rm -rf "{self.resource.target_path.path}"')
