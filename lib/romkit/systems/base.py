from romkit.filters import __all_filters__, BaseFilter, FilterReason, FilterSet, TitleFilter
from romkit.metadata import __all_metadata__, MetadataSet
from romkit.models.collection_set import CollectionSet
from romkit.models.machine import Machine
from romkit.models.romset import ROMSet
from romkit.sorters import __all_sorters__, SortableSet
from romkit.systems.system_dir import SystemDir

import logging
import os
import shlex
import time
import traceback
from copy import copy
from pathlib import Path
from typing import Dict, Generator, List, Optional, Tuple

# Maximum number of times we'll attempt to install a machine
INSTALL_MAX_ATTEMPTS = os.getenv('INSTALL_MAX_ATTEMPTS', 3)
INSTALL_RETRY_WAIT_TIME = os.getenv('INSTALL_RETRY_WAIT_TIME', 30) # seconds

class BaseSystem:
    name = 'base'

    # Filters that run based on an allowlist/blocklist provided at runtime
    supported_filters = __all_filters__
    supported_metadata = __all_metadata__
    supported_sorters = __all_sorters__

    def __init__(self, config: dict) -> None:
        self.config = config
        self.name = config['system']
        self.download_config = config.get('downloads', {})

        # External metadata to load for filtering purposes
        self.metadata_set = MetadataSet.from_json(config.get('metadata', {}), self.supported_metadata)

        # Install directories
        file_templates = config['roms']['files']
        self.dirs = [
            SystemDir(
                dir_config['path'],
                FilterSet.from_json(dir_config.get('filters', {}), config, self.supported_filters, log=False),
                dir_config.get('context', {}),
                file_templates,
            )
            for dir_config in config['roms']['dirs']
        ]

        # Favorites (defaults to false if no favorites are provided)
        self.favorites_set = FilterSet.from_json(config['roms'].get('favorites', {}), config, self.supported_filters, log=False)
        self.favorites_set.default_on_empty = False

        # Collections
        self.collection_set = CollectionSet.from_json(config['roms'].get('collections', {}), config, self.supported_filters)

        # Attribute type to define the unique machine identifier
        self.rom_id_type = config['roms']['id']

        # Filters
        self.filter_set = FilterSet.from_json(config['roms'].get('filters', {}), config, self.supported_filters)

        # Track machines that have been filtered / prioritized
        self._loaded = False
        self.machines = SortableSet.from_json(self.config['roms'].get('priority', {}), self.supported_sorters)
        self.prioritized_machines = []

    # Looks up the system from the given name
    @classmethod
    def from_json(cls, json: dict) -> None:
        name = json['system']

        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls(json)

        return cls(json)

    # Iterates over the romsets available to this system
    def iter_romsets(self) -> Generator[None, ROMSet, None]:
        for romset_name, romset_config in self.config['romsets'].items():
            romset_config['name'] = romset_name
            yield ROMSet.from_json(romset_config, system=self, downloads=self.download_config)

    # Sorts the machines available in each romset
    def load(self, force: bool = False) -> bool:
        if self._loaded and not force:
            return False

        self.machines.clear()
        self.prioritized_machines.clear()

        for romset in self.iter_romsets():
            for machine, allow_reason in self._filter_romset(romset).items():
                if allow_reason == FilterReason.OVERRIDE:
                    self.machines.override(machine)
                else:
                    self.machines.add(machine)

        self.prioritized_machines = self.machines.prioritize()

        # Update favorites / collections
        for machine in self.prioritized_machines:
            machine.favorite = self.favorites_set.allow(machine) == FilterReason.ALLOW
            machine.collections.update(self.collection_set.list(machine))

        self._loaded = True
        return True

    # Filters the machines in the given romset
    def _filter_romset(self, romset: ROMSet) -> Dict[Machine, FilterReason]:
        return romset.filter_machines(self.filter_set, self.metadata_set)

    # Generates the list of machines to target, based are predefined priorities
    def list(self) -> List[Machine]:
        self.load()
        return sorted(self.prioritized_machines, key=lambda machine: machine.name)

    # Installs all of the filtered machines
    def install(self) -> None:
        # Install and filter out invalid machines
        machines = self.list()
        for machine in machines:
            machine.before_install()

        for machine in machines:
            self.install_machine(machine)

        self.organize()

    # Installs the given machine and returns true/false depending on whether the
    # install was successful
    def install_machine(self, machine: Machine) -> bool:
        for attempt in range(INSTALL_MAX_ATTEMPTS):
            try:
                machine.install()
                return True
            except Exception as e:
                logging.error(f'[{machine.name}] Install failed')
                traceback.print_exc()
                time.sleep(INSTALL_RETRY_WAIT_TIME)

        return False

    # Organizes the directory structure based on the current list of valid
    # installed machines
    def organize(self) -> None:
        self.load()
        self.reset_directories()

        for machine in self.prioritized_machines:
            if not machine.is_valid_nonmerged():
                logging.warn(f'[{machine.name}] is not a valid non-merged ROM')
                continue

            # Enable machine in directories that are filtering for it
            machine.clean()
            for system_dir in self.dirs:
                if system_dir.allow(machine):
                    self.enable_machine(machine, system_dir)

    # Reset the visible set of machines
    def reset_directories(self) -> None:
        for system_dir in self.dirs:
            system_dir.reset()

    # Enables the given machine in the given directory
    def enable_machine(self, machine: Machine, system_dir: SystemDir) -> None:
         machine.enable(system_dir)

    # Purges machines that were not installed
    def vacuum(self) -> None:
        # Identify all of the valid paths for machines that are installed
        installable_paths = set()
        for machine in self.list():
            resource_models = list(filter(None, {machine, machine.sample, machine.playlist} | machine.disks))

            for resource_model in resource_models:
                resource = resource_model.resource
                if resource:
                    installable_paths.add(resource.target_path.path)
                    if resource.is_locally_sourced:
                        installable_paths.add(resource.source_url_path)
                    if resource.xref_path:
                        installable_paths.add(resource.xref_path.path)

        # Identify the installable path globs.  It's important that the context
        # includes all of the necessary glob patterns, otherwise this'll error out.
        installable_path_globs = set()
        resource_names = {'machine', 'disk', 'sample', 'playlist'}
        resource_context = {
            'disk': '*',
            'machine': '*',
            'machine_alt_name': '*',
            'machine_description': '*',
            'machine_id': '*',
            'machine_sourcefile': '*',
            'parent': '*',
            'playlist': '*',
            'rom_root': '*',
            'sample': '*',
            'sha1': '*',
            'url': '',
        }
        for romset in self.iter_romsets():
            for resource_name in resource_names:
                resource = romset.resource(resource_name, **resource_context)
                if resource:
                    resource_paths = map(
                        lambda resource_path: resource_path.path,
                        filter(None, [
                            resource.download_path,
                            resource.target_path,
                            resource.xref_path,
                        ])
                    )

                    installable_path_globs.update(resource_paths)

        # Look up all files that match the path template glob pattern.  If they
        # weren't tracked as an installable resource, then we know they can be
        # deleted.
        for path_glob in installable_path_globs:
            for path in Path('/').glob(str(path_glob)[1:]):
                if path not in installable_paths:
                    print(f'rm -rfv {shlex.quote(str(path))}')
