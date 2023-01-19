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
from typing import Generator, List, Optional, Tuple

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

        # Priority order for choosing a machine (e.g. 1G1R)
        self.sorted_machines = SortableSet.from_json(config['roms'].get('priority', {}), self.supported_sorters)

        # Favorites (defaults to false if no favorites are provided)
        self.favorites_set = FilterSet.from_json(config['roms'].get('favorites', {}), config, self.supported_filters, log=False)
        self.favorites_set.default_on_empty = False

        # Collections
        self.collection_set = CollectionSet.from_json(config['roms'].get('collections', {}), config, self.supported_filters)

        # Attribute type to define the unique machine identifier
        self.rom_id_type = config['roms']['id']

        # Filters
        self.filter_set = FilterSet.from_json(config['roms'].get('filters', {}), config, self.supported_filters)

    # Looks up the system from the given name
    @classmethod
    def from_json(cls, json: dict) -> None:
        name = json['system']

        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls(json)

        return cls(json)

    # Additional context for rendering Machine URLs
    def context_for(self, machine: Machine) -> dict:
        return {}

    def iter_romsets(self) -> Generator[None, ROMSet, None]:
        # Load romsets
        for romset_config in self.config['romsets']:
            yield ROMSet.from_json(romset_config, system=self, downloads=self.download_config)

    def list(self) -> List[Machine]:
        # Machines guaranteed to be installed
        self.sorted_machines.clear()

        for romset in self.iter_romsets():
            # Machines that are installable or required by installable machines
            machines_to_track = set()

            for machine in romset.iter_machines():
                # Update based on metadata database
                self.metadata_set.update(machine)

                allow_reason = self.filter_set.allow(machine)
                if allow_reason:
                    # Track this machine and all machines it depends on
                    machines_to_track.update(machine.dependent_machine_names)
                    machine.track()

                    # Force the machine to be installed if it was allowed by an override
                    if allow_reason == FilterReason.OVERRIDE:
                        self.sorted_machines.override(machine)
                    else:
                        self.sorted_machines.add(machine)
                elif not machine.is_clone:
                    # We track all parent/bios machines in case they're needed as a dependency
                    # in future machines.  We'll confirm later on with `machines_to_track`.
                    machine.track()

            # Free memory by removing machines we didn't need to keep
            for name in romset.machine_names:
                if name not in machines_to_track:
                    romset.remove(name)

        # Get the final, sorted/prioritized list of machines
        machines_to_install = self.sorted_machines.prioritize()

        # Update favorites / collections
        for machine in machines_to_install:
            # Set whether the machine is a favorite
            machine.favorite = self.favorites_set.allow(machine) == FilterReason.ALLOW
            machine.collections.update(self.collection_set.list(machine))

        # Sort by name
        return sorted(machines_to_install, key=lambda machine: machine.name)

    # Installs all of the filtered machines
    def install(self) -> None:
        # Install and filter out invalid machines
        machines = self.list()
        for machine in machines:
            machine.before_install()

        for machine in machines:
            self.install_machine(machine)

        self.organize(machines)

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
    def organize(self, machines: Optional[List[Machine]] = None) -> None:
        if not machines:
            machines = self.list()
        
        valid_machines = []
        for machine in machines:
            if machine.is_valid_nonmerged():
                valid_machines.append(machine)
            else:
                logging.warn(f'[{machine.name}] is not a valid non-merged ROM')

        self.reset()
        self.enable(valid_machines)

    # Reset the visible set of machines
    def reset(self) -> None:
        for system_dir in self.dirs:
            system_dir.reset()

    # Enables the given list of machines so they're visible
    def enable(self, machines: List[Machine]) -> None:
        for machine in machines:
            # Machine is valid: Enable
            machine.clean()

            for system_dir in self.dirs:
                # Enable machine in directories that are filtering for it
                if system_dir.allow(machine):
                    self.enable_machine(machine, system_dir)

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
