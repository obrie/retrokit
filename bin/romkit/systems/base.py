from romkit.filters import CloneFilter, ControlFilter, EmulatorFilter, FilterSet, FlagFilter, KeywordFilter, NameFilter, TitleFilter
from romkit.models import EmulatorSet, Machine, ROMSet
from romkit.systems.system_dir import SystemDir

import logging
import traceback
from copy import copy
from pathlib import Path
from typing import Generator, List, Tuple

class BaseSystem:
    name = 'base'

    # Filters that run based on an allowlist/blocklist provided at runtime
    supported_filters = [
        CloneFilter,
        KeywordFilter,
        FlagFilter,
        ControlFilter,
        NameFilter,
        TitleFilter,
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
        self.machine_priority = config['roms'].get('priority', set())

        # Emulator compatibility
        if 'emulators' in config['roms']:
            self.emulator_set = self.emulator_set_class.from_json(self, config['roms']['emulators'])
        else:
            self.emulator_set = self.emulator_set_class(self)

        # Filters
        self.filter_set = FilterSet.from_json(config['roms'].get('filters', {}), config, self.supported_filters)

        # Filters: emulators
        if self.emulator_set.filter:
            self.filter_set.append(EmulatorFilter(config=self.config))

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
        # Filter and group by the base name (so, for example, multiple
        # games with different revisions will be grouped together)
        groups = {}

        for romset in self.iter_romsets():
            # Machines that are installable or required by installable machines
            machines_to_track = set()

            for machine in romset.iter_machines():
                # Set the emulator on the machine if we have it based on the
                # system-wide defaults
                if not machine.emulator:
                    machine.emulator = self.emulator_set.get(machine)

                if self.filter_set.allow(machine):
                    # Track this machine and all machines it depends on
                    machines_to_track.update(machine.dependent_machine_names)
                    machine.track()

                    # Group the machine based on its title (no flags)
                    title = machine.title
                    if title not in groups:
                        groups[title] = []
                    groups[title].append(machine)
                elif not machine.is_clone:
                    # We track all parent/bios machines in case they're needed as a dependency
                    # in future machines.  We'll confirm later on with `machines_to_track`.
                    machine.track()

            # Free memory by removing machines we didn't need to keep
            for name in list(romset.machines):
                if name not in machines_to_track:
                    romset.remove(name)

        # Prioritize the machines within each group
        machines_by_name = {}
        for title, grouped_machines in groups.items():
            # Find the highest-priority machine
            prioritized_machines = sorted(grouped_machines, key=self._sort_machines)
            prioritized_machine = prioritized_machines[0]
            machines_by_name[prioritized_machine.name] = prioritized_machine

            # Log all of the machines that were de-prioritized
            for machine in prioritized_machines[1:]:
                logging.debug(f'[{machine.name}] Skip (PriorityFilter)')

        return machines_by_name.values()

    # Sorts machines based on a predefined priority ordering.
    # 
    # If two machines have the same priority, the machine with the shortest name
    # is chosen.
    def _sort_machines(self, machine: Machine) -> Tuple[int, int]:
        # Default priority is lowest
        priority_index = len(self.machine_priority)

        for index, search_string in enumerate(self.machine_priority):
            if search_string in machine.flags_str:
                # Found a matching priority string: track the index
                priority_index = index
                break

        return (priority_index, len(machine.name))

    # Installs all of the filtered machines
    def install(self) -> None:
        # Install and filter out invalid machines
        valid_machines = filter(self.install_machine, self.list())

        self.reset()
        self.enable(valid_machines)

    # Installs the given machine and returns true/false depending on whether the
    # install was successful
    def install_machine(self, machine: Machine) -> bool:
        try:
            machine.install()
            return machine.is_valid_nonmerged
        except Exception as e:
            logging.error(f'[{machine.name}] Install failed')
            traceback.print_exc()
            return False

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
