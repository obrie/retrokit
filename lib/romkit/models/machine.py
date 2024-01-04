from __future__ import annotations

from romkit.models.asset import Asset
from romkit.models.disk import Disk
from romkit.models.file import File
from romkit.models.playlist import Playlist
from romkit.models.sample import Sample

import hashlib
import logging
import re
from pathlib import Path
from typing import Dict, List, Optional, Set

# Represents a Game/Device/BIOS
class Machine:
    FLAG_REGEX = re.compile(r'[\(\[]([^\)\])]+)[\)\]]')
    FLAG_DELIMITER_REGEX = re.compile(r', *')
    ROOT_REGEX = re.compile(r'^([^\\/]+)')
    NORMALIZED_TITLE_REGEX = re.compile(r'[^a-z0-9\+&\.]+')

    # The names of resources that have custom handling
    CUSTOM_RESOURCE_NAMES = {'machine', 'disk', 'sample', 'dat', 'playlist'}

    def __init__(self,
        romset: ROMSet,
        name: str,

        # Internal metadata
        description: str = '',
        comment: str = '',
        orientation: str = 'horizontal',
        category: Optional[str] = None,
        sourcefile: Optional[str] = None,
        controls: Set[str] = None,
        peripherals: Set[str] = None,
        buttons: List[str] = None,

        # File data
        parent_name: Optional[str] = None,
        bios_name: Optional[str] = None,
        sample_name: Optional[str] = None,
        device_names: Set[str] = None,
        roms: Set[File] = None,
        disks: Set[Disk] = None,
        is_bios: bool = False,
        is_mechanical: bool = False,
        runnable: bool = True,

        # External metadata
        group_name: Optional[str] = None,
        year: Optional[int] = None,
        developers: Set[str] = None,
        publishers: Set[str] = None,
        age_rating: Optional[str] = None,
        genres: Set[str] = None,
        collections: Set[str] = None,
        tags: Set[str] = None,
        custom: Optional[dict] = None,
        languages: Set[str] = None,
        rating: Optional[float] = None,
        players: Optional[int] = None,
        discs: Optional[int] = None,
        emulator_rating: Optional[int] = None,
        manual: Optional[dict] = None,
        media: Optional[dict] = None,
        series: Optional[str] = None,

        # Additional context to include when rendering resource paths
        custom_context: dict = None,
    ) -> None:
        self.romset = romset
        self.name = name
        self.alt_names = []

        # Keeps track of any other machines that are needed to run this one, such as:
        # * Parent
        # * BIOS
        # * Device
        # 
        # Maps name -> Machine
        self.dependent_machines = {}

        # Internal metadata
        self.description = description or name
        self.comment = comment
        self.orientation = orientation
        self.category = category
        self.sourcefile = sourcefile
        self.controls = controls or set()
        self.peripherals = peripherals or set()
        self.buttons = buttons or []

        # File data
        self.parent_name = parent_name
        self.bios_name = bios_name
        self.sample_name = sample_name
        self.device_names = device_names or set()
        self.roms = roms or set()
        self.disks = disks or set()
        self.is_bios = is_bios
        self.is_mechanical = is_mechanical
        self.runnable = runnable

        # External attributes
        self.year = year
        self.developers = developers or set()
        self.publishers = publishers or set()
        self.age_rating = age_rating
        self.genres = genres or set()
        self.collections = collections or set()
        self.tags = tags or set()
        self.custom = custom or {}
        self.languages = languages or set()
        self.rating = rating
        self.players = players
        self.discs = discs or 1
        self.emulator_rating = emulator_rating
        self.manual = manual
        self.media = media or {}
        self.series = series or set()
        self.group_name = group_name or self.parent_title or self.title

        # Automatic defaults
        self.emulator = romset.emulators[0] if romset.emulators else None
        self.favorite = False
        self.custom_context = custom_context or {}

        self._resource = None

    # Whether this machine is installable
    @staticmethod
    def is_installable(xml: lxml.etree.ElementBase) -> bool:
        return (xml.get('isbios') != 'true' and xml.get('isdevice') != 'true') or xml.find('rom') is not None

    @classmethod
    def from_xml(cls, romset: ROMSet, xml: lxml.etree.ElementBase) -> Machine:
        name = xml.get('name')

        # Parent / BIOS
        parent_name = xml.get('cloneof')
        bios_name = xml.get('romof')
        if bios_name == parent_name:
            bios_name = None

        sourcefile = xml.get('sourcefile')
        is_bios = xml.get('isbios') == 'yes' or name.startswith('[BIOS]')
        is_mechanical = xml.get('ismechanical') == 'yes'
        runnable = xml.get('runnable') != 'no'
        sample_name = xml.get('sampleof')

        # Defaults for data based on child elements
        description = None
        category = None
        comment = None
        year = None
        manufacturer = None
        device_names = set()
        dumped_disks = []
        dumped_roms = []

        has_machine_template = 'machine' in romset.enabled_resource_templates

        for child in xml:
            tag = child.tag

            if tag == 'device_ref':
                # Devices
                device_names.add(child.get('name'))
            elif tag == 'sample':
                # In older dat files, sampleof wasn't included in the parent.
                # We fall back to checking if there are any <sample /> children
                # and assume the sample archive is the same name as this machine.
                if not sample_name:
                    sample_name = name
            elif tag == 'category':
                category = child.text
            elif tag == 'comment':
                comment = child.text
            elif tag == 'year':
                if child.text.isnumeric():
                    year = int(child.text)
            elif tag == 'manufacturer':
                manufacturer = child.text
            elif tag == 'description':
                description = child.text
            elif tag == 'disk':
                if Disk.is_installable(child):
                    dumped_disks.append(child)
            elif tag == 'rom':
                if has_machine_template and File.is_installable(child):
                    dumped_roms.append(child)

        machine = cls(
            romset,
            name,
            description=description,
            comment=comment,
            category=category,
            is_bios=is_bios,
            is_mechanical=is_mechanical,
            runnable=runnable,
            parent_name=parent_name,
            bios_name=bios_name,
            sample_name=sample_name,
            device_names=device_names,
            sourcefile=sourcefile,
            year=year,
            developers=manufacturer and {manufacturer},
        )

        # Disks
        machine.disks = {Disk(machine, disk_xml.get('name'), disk_xml.get('sha1')) for disk_xml in dumped_disks}

        # ROMs
        if has_machine_template:
            file_identifier = romset.resource_templates['machine'].file_identifier
            machine.roms = {File.from_xml(rom_xml, file_identifier=file_identifier) for rom_xml in dumped_roms}

        return machine

    @classmethod
    def from_dict(cls, romset: ROMSet, attrs: dict) -> Machine:
        machine_attrs = {key: attrs[key] for key in attrs if key not in ['disks', 'roms']}
        machine = cls(romset, **machine_attrs)

        # Disks
        if 'disks' in attrs:
            machine.disks = {Disk(machine, **disk_attrs) for disk_attrs in attrs['disks']}

        # ROMs
        if 'roms' in attrs:
            machine.roms = {
                File(**rom_attrs, file_identifier=romset.resource_templates['machine'].file_identifier)
                for rom_attrs in attrs['roms']
            }

        return machine

    # Tracks this machine so that it can be referenced later from the romset
    def track(self) -> None:
        self.romset.track(self)

    # Generates a unique identifier for this machine so that if the name changes
    # from romset release to romset release, we can still reference the original
    # without having to re-download from the source.
    @property
    def id(self) -> str:
        rom_id_type = self.romset.system.rom_id_type
        if rom_id_type == 'crc':
            # Exclude cue files since they will always change when the name changes
            roms = filter(lambda file: Path(file.name).suffix != '.cue', self.roms)
            rom_crcs = [file.crc for file in roms]

            # Sort to ensure any change in rom order has no effect
            rom_crcs.sort()

            # Generate hash based on the underlying ROMs
            machine_id = hashlib.sha1(''.join(rom_crcs).encode()).hexdigest()
        elif rom_id_type == 'name':
            machine_id = self.name
        else:
            raise Exception(f'Invalid rom id type: {rom_id_type}')

        return machine_id

    # Builds context for formatting dirs/urls, including resource filenames
    @property
    def context(self) -> dict:
        context = {**self._resource_context}
        if self.resource:
            context['machine_filename'] = self.resource.target_path.path.name

        return context

    # Builds context for formatting dirs/urls
    @property
    def _resource_context(self) -> dict:
        return {
            'machine': self.name,
            'machine_letter': ('0' if self.name[0].isnumeric() else self.name[0].upper()),
            'machine_id': self.id,
            'machine_alt_names': self.alt_names,
            'machine_description': self.description,
            'machine_sourcefile': self.sourcefile or self.name,
            'rom_root': self.rom_root,
            'parent': (self.parent_name or self.name),
            'primary_rom': (self.primary_rom and self.primary_rom.name),
            'primary_rom_basename': (self.primary_rom and Path(self.primary_rom.name).name),
            **self.custom_context,
        }

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

    # Name of the playlist this machine belongs to (even if it's a playlist of 1)
    @property
    def playlist_name(self) -> str:
        return Playlist.name_from(self.name)

    # The title of the group this machine is assigned to
    @property
    def group_title(self) -> str:
        return self.title_from(self.group_name)

    # Builds a title from the given name
    @classmethod
    def title_from(cls, name: str, disc: bool = False) -> str:
        flag_start_index = name.find('(')
        if flag_start_index != -1:
            title = name[0:flag_start_index].strip()
        else:
            title = name

        if disc:
            disc_match = Playlist.DISC_REGEX.search(name)
            if disc_match:
                title = f'{title}{disc_match.group()}'

        return title

    # Normalizes the given machine name by removing characters that may differ
    # between romsets
    @classmethod
    def normalize(cls, name: str) -> str:
        if name:
            return cls.NORMALIZED_TITLE_REGEX.sub('', name.lower())

    # Flags part of the description
    @property
    def flags_description(self) -> str:
        flag_start = self.description.find('(')
        if flag_start >= 0:
            return self.description[flag_start:]
        else:
            return ''

    # Groups of flags from the description
    @property
    def flag_groups(self) -> Set[str]:
        return self.FLAG_REGEX.findall(self.flags_description)

    # Individual flags from the description
    @property
    def flags(self) -> Set[str]:
        values = set()
        for group in self.flag_groups:
            values.update(self.FLAG_DELIMITER_REGEX.split(group))
        return values

    # Estimated filesize in bytes
    @property
    def filesize(self) -> int:
        return sum(map(lambda file: file.size, self.non_merged_roms))

    # Primary rom in the machine.  This is either going to be the *only*
    # rom or a cue that represents multiple rom files.
    # 
    # Not that only roms that are contributed by this machine are considered.
    # A rom from a parent, bios, or device cannot be considered a primary rom
    # for this machine.
    @property
    def primary_rom(self) -> Optional[File]:
        roms = self.roms_from_self

        if len(roms) == 1:
            # Only one rom in the machine -- that's the primary one
            return next(iter(roms))
        elif len(roms) > 1:
            # Multiple roms -- see if there's a cue file
            cue_file = next(filter(lambda rom: '.cue' in rom.name, roms), None)
            if cue_file:
                return cue_file

            # Pick the largest file as a last resort
            return sorted(roms, key=lambda file: [file.size, file.name])[-1]

    # Target destination for installing this sample
    @property
    def resource(self) -> Resource:
        if not self._resource:
            self._resource = self.romset.resource('machine', **self._resource_context)
        return self._resource

    # Parent machine, if applicable
    @property
    def parent_machine(self) -> Optional[Machine]:
        if self.parent_name:
            return self.dependent_machines[self.parent_name]

    # BIOS machine, if applicable, as defined either in this machine or in the
    # parent machine
    @property
    def bios_machine(self) -> Optional[Machine]:
        if self.bios_name:
            return self.dependent_machines.get(self.bios_name)
        elif self.parent_machine and self.parent_machine.bios_machine:
            return self.parent_machine.bios_machine

    # Devices that are required to run this machine
    @property
    def device_machines(self) -> List[Machine]:
        machines = []
        for device_name in self.device_names:
            machine = self.dependent_machines.get(device_name)
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

    # ROMs installed directly from the given machine (excluding any bios)
    # 
    # Note that this assumes ROMs have either the same CRC or the
    # same name.  If using "name" as the file_identifier but the
    # parent ROM has a different name, this will be broken.  We could
    # utilize the @merge property on ROMs to fix this, but at the
    # moment there's no need.
    def roms_from(self, machine: Machine) -> Set[File]:
        machine_roms = machine.roms_from_self
        non_merged_roms = self.non_merged_roms

        return set(rom for rom in non_merged_roms if rom in machine_roms)

    # ROMs installed directly from this machine
    @property
    def roms_from_self(self) -> Set[File]:
        # roms does *not* include roms from device machines, so we only need
        # to exclude those roms from the parent and bios
        roms = self.roms
        if self.parent_machine:
            roms = roms - self.parent_machine.roms

        if self.bios_machine:
            roms = roms - self.bios_machine.roms

        return roms

    # All ROMs expected to be in the non-merged build (from self, parent, bios, and devices)
    @property
    def non_merged_roms(self) -> Set[File]:
        # Define the machines containing the lists of roms required
        # for a non-merged archive
        machines = [self] # includes self, parent, and bios
        machines.extend(self.device_machines)

        # Build up the full set of ROMs required
        roms = set()
        for machine in machines:
            roms.update(machine.roms)

        return roms

    # Root folder that the ROMs live in (may not be applicable to the current romset)
    @property
    def rom_root(self) -> Optional[str]:
        if self.roms:
            return self.ROOT_REGEX.search(next(iter(self.roms)).name).group()
        else:
            return ''

    # Disks installed from the parent
    @property
    def disks_from_parent(self) -> Set[Disk]:
        if self.parent_machine:
            # Avoid set intersection to guarantee we'll use the parent's disks
            # instead of ours since machines will be compatible with the
            # installation from the parent
            return set(disk for disk in self.parent_machine.disks if disk in self.disks)
        else:
            return set()

    # Disks installed directly from this machine
    @property
    def disks_from_self(self) -> Set[Disk]:
        return self.disks - self.disks_from_parent

    # Audio sample
    @property
    def sample(self) -> Optional[Sample]:
        if self.sample_name:
            return Sample(self, self.sample_name)

    # Whether this machine is part of a group of related machines in a playlist
    @property
    def has_playlist(self) -> bool:
        return self.disc_title != self.title

    # Playlist for multi-disc machines
    @property
    def playlist(self) -> Optional[Playlist]:
        if self.has_playlist and self.romset.has_resource('playlist'):
            return Playlist(self)

    # External assets
    @property
    def assets(self) -> Set[Asset]:
        assets = set()

        for name in self.romset.enabled_resource_templates.keys():
            if name not in self.CUSTOM_RESOURCE_NAMES:
                assets.add(Asset(self, name))

        return assets

    # Generates data for use in output actions
    def dump(self) -> Dict[str, str]:
        data = {
            'system': self.romset.system.name,
            'romset': self.romset.name,

            # Taxonomy
            'name': self.name,
            'id': self.id,
            'disc': self.disc_title,
            'title': self.title,
            'category': self.category,

            # ROM info
            'path': self.resource and str(self.resource.target_path.path),
            'filesize': self.filesize,
            'description': self.description,
            'comment': self.comment,
            'is_bios': self.is_bios,
            'runnable': self.runnable,
            'is_mechanical': self.is_mechanical,

            # Download info
            'url': self.resource and str(self.resource.source_url),

            # User overrides
            'favorite': self.favorite,

            # External metadata
            'year': self.year,
            'developers': self.developers,
            'publishers': self.publishers,
            'age_rating': self.age_rating,
            'genres': self.genres,
            'collections': self.collections,
            'languages': self.languages,
            'rating': self.rating,
            'players': self.players,
            'discs': self.discs,
            'emulator': self.emulator,
            'emulator_rating': self.emulator_rating,
            'manual': self.manual,
            'media': self.media,
            'series': self.series,
            'orientation': self.orientation,
            'controls': self.controls,
            'peripherals': self.peripherals,
            'buttons': self.buttons,
            'tags': self.tags,
            'custom': self.custom,
            'group': {
                'name': self.group_name,
                'title': self.group_title,
            }
        }

        primary_rom = self.primary_rom
        if primary_rom:
            data['rom'] = {
                'name': primary_rom.name,
                'crc': primary_rom.crc and primary_rom.crc.upper(),
            }

        playlist = self.playlist
        if playlist:
            data['playlist'] = {
                'name': playlist.name
            }

        if self.parent_name:
            data['parent'] = {
                'name': self.parent_name,
                'disc': self.parent_disc_title,
                'title': self.parent_title
            }

        if self.resource and self.resource.xref_path:
            data['xref'] = {
                'path': str(self.resource.xref_path.path),
            }

        return data

    # Determines whether the locally installed set of ROMs is equal to the full set of
    # non_merged roms
    def is_valid_nonmerged(self) -> bool:
        return not self.resource or not self.non_merged_roms or self.resource.contains(self.non_merged_roms)

    # Runs any actions required before the machine is installed
    def before_install(self) -> None:
        if self.playlist:
            # Delete existing playlists so that we start empty as each machine
            # gets added to it.  We prefer this over re-using the existing list
            # in case the previous playlist was bad or the number of discs has
            # been reduced.
            self.playlist.delete()

    # Installs the given resources for this machine onto the local filesystem
    def install(self, resource_names: Set[str] = None) -> None:
        if not resource_names:
            resource_names = {'machine', 'device', 'disk', 'sample', 'playlist', *(asset.name for asset in self.assets)}

        if 'machine' in resource_names:
            if self.resource:
                self.resource.check_xref()

            # Always install from self first in case we're working with a non-merged source
            self.install_from(self)
            self.install_from(self.parent_machine)
            self.install_from(self.bios_machine)

            if self.resource:
                # Special cases where there were no roms (e.g. pong in mame)
                if not self.resource.exists():
                    logging.info(f'[{self.name}] Creating empty resource')
                    self.resource.target_path.touch()

                self.resource.create_xref()

        # Devices
        if 'device' in resource_names:
            for device_machine in self.device_machines:
                self.install_from(device_machine)

        # Disks
        if 'disk' in resource_names:
            for disk in (self.disks_from_self | self.disks_from_parent):
                disk.install()

        # Samples
        if self.sample and 'sample' in resource_names:
            self.sample.install()

        # Playlist
        if self.playlist and 'playlist' in resource_names:
            self.playlist.install()

        # Assets
        for asset in self.assets:
            if asset.name in resource_names:
                asset.install()

    # Installs the roms from the given source machine
    def install_from(self, machine: Machine) -> None:
        if not machine or not self.resource:
            return

        # Find matching ROMs to install
        roms = self.roms_from(machine)
        if self.resource.predefined and not roms:
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
        if not(self.resource and self.resource.predefined):
            return

        # Clean the resource
        self.resource.clean(self.non_merged_roms)

    # Enables this machine to be visible to the emulator
    def enable(self, target_dir: SystemDir):
        logging.info(f'[{self.name}] Enabling in: {target_dir.path}')

        if self.playlist:
            # When there's a playlist, it's the only thing from the machine that
            # needs to get enabled
            self.playlist.enable(target_dir)
        elif self.resource:
            # Disks get handled separately -- everything else gets symlink'd
            # through the machine's resource
            for resource_name in (target_dir.file_templates.keys() - set(['disk', 'playlist'])):
                target_dir.symlink(resource_name, self.resource, **self.context)

        for disk in (self.disks_from_self | self.disks_from_parent):
            disk.enable(target_dir)
