from romkit.filters import __all_filters__, BaseFilter, FilterReason, FilterSet, TitleFilter
from romkit.metadata import __all_metadata__, MetadataSet
from romkit.models.machine import Machine
from romkit.models.romset import ROMSet
from romkit.sorters import __all_sorters__, SorterSet
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

    def __init__(self, config: dict, demo: bool = True) -> None:
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
        self.machine_priority = SorterSet.from_json(config['roms'].get('priority', {}), self.supported_sorters)

        # Favorites (defaults to false if no favorites are provided)
        self.favorites_set = FilterSet.from_json(config['roms'].get('favorites', {}), config, self.supported_filters)

        # Attribute type to define the unique machine identifier
        self.rom_id_type = config['roms']['id']

        if demo:
            # Just the demo filter
            self.filter_set = FilterSet()
            self.filter_set.append(TitleFilter(config['roms']['filters']['demo'], config=config))
        else:
            # Filters
            self.filter_set = FilterSet.from_json(config['roms'].get('filters', {}), config, self.supported_filters)

            # Filters: forced name filters
            auxiliary_filter_sets = list(map(lambda system_dir: system_dir.filter_set, self.dirs)) + [self.favorites_set]
            for filter_set in auxiliary_filter_sets:
                for filter in filter_set.filters:
                    if filter.name == 'names':
                        new_filter = copy(filter)
                        new_filter.override = True
                        self.filter_set.append(new_filter)

    # Looks up the system from the given name
    @classmethod
    def from_json(cls, json: dict, demo: bool = False) -> None:
        name = json['system']

        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls(json, demo)

        return cls(json, demo)

    # Additional context for rendering Machine URLs
    def context_for(self, machine: Machine) -> dict:
        return {}

    def iter_romsets(self) -> Generator[None, ROMSet, None]:
        # Load romsets
        for romset_config in self.config['romsets']:
            yield ROMSet.from_json(romset_config, system=self, downloads=self.download_config)

    def list(self) -> List[Machine]:
        # Machines guaranteed to be installed
        machines_to_install = set()

        # Machines that are candidates until we've gone through all of them
        machine_candidates = {}

        # Normalized title => groupd id
        machine_groups = {}

        for romset in self.iter_romsets():
            # Machines that are installable or required by installable machines
            machines_to_track = set()

            for machine in romset.iter_machines():
                # Set external emulator metadata
                self.metadata_set.update(machine)

                # Set whether the machine is a favorite
                machine.favorite = self.favorites_set.allow(machine) == FilterReason.ALLOW

                allow_reason = self.filter_set.allow(machine)
                if allow_reason:
                    # Track this machine and all machines it depends on
                    machines_to_track.update(machine.dependent_machine_names)
                    machine.track()

                    # Group the machine based on its parent/self title (w/ disc).
                    # We don't want to rely on the group name because (a) we don't always
                    # have a Parent/Clone relationship map and (b) the flags are
                    # less stable.
                    normalized_disc_title = Machine.normalize(machine.disc_title)
                    normalized_parent_disc_title = Machine.normalize(machine.parent_disc_title)
                    group = (normalized_parent_disc_title and machine_groups.get(normalized_parent_disc_title)) or machine_groups.get(normalized_disc_title) or normalized_parent_disc_title or normalized_disc_title
                    machine_groups[normalized_disc_title] = group
                    if normalized_parent_disc_title:
                        machine_groups[normalized_parent_disc_title] = group

                    # Force the machine to be installed if it was allowed by an override
                    if allow_reason == FilterReason.OVERRIDE:
                        machines_to_install.add(machine)

                        # Avoid installing anything else in the group that was a candidate
                        machine_candidates[group] = machine

                    # If a priority is defined, the user is asking for a 1G1R setup.
                    # In that case, we either choose a machine that was explicitly overridden
                    # for install or we choose the highest priority machine in the group.
                    if self.machine_priority.enabled:
                        existing = machine_candidates.get(group)

                        if not existing:
                            # First time we've seen this group: make the machine the default
                            machine_candidates[group] = machine
                        elif existing not in machines_to_install:
                            # Decide which of the two machines to install based on the
                            # predefined priority order
                            prioritized_machines = self.machine_priority.sort([existing, machine])
                            machine_candidates[group] = prioritized_machines[0]
                            logging.debug(f'[{prioritized_machines[1].name}] Skip (PriorityFilter)')
                    else:
                        # No priority defined: Add all machines
                        machines_to_install.add(machine)
                elif not machine.is_clone:
                    # We track all parent/bios machines in case they're needed as a dependency
                    # in future machines.  We'll confirm later on with `machines_to_track`.
                    machine.track()

            # Free memory by removing machines we didn't need to keep
            for name in romset.machine_names:
                if name not in machines_to_track:
                    romset.remove(name)

        # Add all the candidates now that we've gone through all the machines
        machines_to_install.update(machine_candidates.values())

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
