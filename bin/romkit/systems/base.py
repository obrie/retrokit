from romkit.filters import BaseFilter, CloneFilter, ControlFilter, EmulatorFilter, EmulatorCompatibilityFilter, FilterReason, FilterSet, FlagFilter, KeywordFilter, NameFilter, OrientationFilter, ROMSetFilter, TitleFilter
from romkit.models import EmulatorSet, Machine, ROMSet
from romkit.systems.system_dir import SystemDir

import logging
import traceback
from copy import copy
from pathlib import Path
from typing import Generator, List, Optional, Tuple

class BaseSystem:
    name = 'base'

    # Filters that run based on an allowlist/blocklist provided at runtime
    supported_filters = [
        CloneFilter,
        KeywordFilter,
        FlagFilter,
        ControlFilter,
        NameFilter,
        OrientationFilter,
        TitleFilter,
        ROMSetFilter,
        EmulatorFilter,
    ]

    # Class to use for building emulator sets
    emulator_set_class = EmulatorSet

    def __init__(self, config: dict) -> None:
        self.config = config
        self.name = config['system']

        # Install directories
        file_templates = config['roms']['files']
        self.dirs = [
            SystemDir(
                dir_config['path'],
                FilterSet.from_json(dir_config.get('filters', {}), config, self.supported_filters, log=False),
                file_templates,
            )
            for dir_config in config['roms']['dirs']
        ]

        # Priority order for choosing a machine (e.g. 1G1R)
        self.machine_priority = list(BaseFilter.normalize(config['roms'].get('priority', [])))

        # Emulator compatibility
        if 'emulators' in config['roms']:
            self.emulator_set = self.emulator_set_class.from_json(self, config['roms']['emulators'])
        else:
            self.emulator_set = self.emulator_set_class(self)

        # Filters
        self.filter_set = FilterSet.from_json(config['roms'].get('filters', {}), config, self.supported_filters)

        # Filters: emulators
        if self.emulator_set.filter:
            self.filter_set.append(EmulatorCompatibilityFilter(config=self.config))

        # Filters: forced name filters
        for system_dir in self.dirs:
            for filter in system_dir.filter_set.filters:
                if filter.name == 'names':
                    new_filter = copy(filter)
                    new_filter.override = True
                    self.filter_set.append(new_filter)

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
            yield ROMSet.from_json(romset_config, system=self)

    def list(self) -> List[Machine]:
        # Machines guaranteed to be installed
        machines_to_install = set()

        # Machines that are candidates until we've gone through all of them
        machine_candidates = {}

        for romset in self.iter_romsets():
            # Machines that are installable or required by installable machines
            machines_to_track = set()

            for machine in romset.iter_machines():
                # Set the emulator on the machine if we have it based on the
                # emulator set (assuming the emulator isn't defined for the
                # entire romset)
                if not machine.emulator:
                    machine.emulator = self.emulator_set.get(machine)

                allow_reason = self.filter_set.allow(machine)
                if allow_reason:
                    # Track this machine and all machines it depends on
                    machines_to_track.update(machine.dependent_machine_names)
                    machine.track()

                    # Group the machine based on its parent/self title (no flags).
                    # We can't rely on the name because not all DATs for rom sets
                    # have Parent/Child relationships defined.
                    group = machine.group_title

                    # Force the machine to be installed if it was allowed by an override
                    if allow_reason == FilterReason.OVERRIDE:
                        machines_to_install.add(machine)

                        # Avoid installing anything else in the group that was a candidate
                        machine_candidates.pop(group, None)

                    # If a priority is defined, the user is asking for a 1G1R setup.
                    # In that case, we either choose a machine that was explicitly overridden
                    # for install or we choose the highest priority machine in the group.
                    if self.machine_priority:
                        existing = machine_candidates.get(group)

                        if not existing:
                            # First time we've seen this group: make the machine the default
                            machine_candidates[group] = machine
                        elif existing not in machines_to_install:
                            # Decide which of the two machines to install based on the
                            # predefined priority order
                            prioritized_machines = sorted([existing, machine], key=self._sort_machines)
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

    # Sorts machines based on a predefined priority ordering.
    # 
    # If two machines have the same priority, the machine with the shortest name
    # is chosen.
    def _sort_machines(self, machine: Machine) -> Tuple[int, int]:
        # Default priority is lowest
        priority_index = len(self.machine_priority)
        flags_str = machine.flags_str.lower()

        for index, search_string in enumerate(self.machine_priority):
            if search_string in flags_str:
                # Found a matching priority string: track the index
                priority_index = index
                break

        return (priority_index, len(machine.name))

    # Installs all of the filtered machines
    def install(self) -> None:
        # Install and filter out invalid machines
        machines = self.list()
        for machine in machines:
            self.install_machine(machine)

        self.organize(machines)

    # Installs the given machine and returns true/false depending on whether the
    # install was successful
    def install_machine(self, machine: Machine) -> bool:
        try:
            machine.install()
        except Exception as e:
            logging.error(f'[{machine.name}] Install failed')
            traceback.print_exc()

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
        installable_machines = self.list()
        installable_machine_paths = set()
        installable_disk_names = set()
        installable_sample_names = set()

        for machine in installable_machines:
            installable_machine_paths.add(machine.resource.target_path.path)

            # Track disks
            for disk in machine.disks:
                installable_disk_names.add(disk.name)

            # Track samples
            if machine.sample:
                installable_sample_names.add(machine.sample.name)

        for romset in self.iter_romsets():
            for machine in romset.iter_machines():
                if machine.resource.target_path.path not in installable_machine_paths:
                    machine.purge()

                    # Check disks
                    for disk in machine.disks:
                        if disk.name not in installable_disk_names:
                            disk.purge()

                    # Check samples
                    if machine.sample and machine.sample.name not in installable_sample_names:
                        machine.sample.purge()
