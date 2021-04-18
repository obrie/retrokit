from romkit.filters.base import FlagFilter, KeywordFilter, NameFilter, CloneFilter, ControlFilter
from romkit.models import Machine, ROMSet
from romkit.systems.system_dir import SystemDir

import logging
import traceback
from pathlib import Path
from typing import Generator, List, Tuple

class BaseSystem:
    name = 'base'

    # Filters that run based on an allowlist/blocklist provided at runtime
    dynamic_filters = [
        CloneFilter,
        KeywordFilter,
        FlagFilter,
        ControlFilter,
        NameFilter,
    ]

    # Filters that run without configuration
    static_filters = []

    def __init__(self, config: dict) -> None:
        self.config = config
        self.dirs = {
            name: SystemDir(path, config['roms']['files'])
            for name, path in config['roms']['dirs'].items()
        }
        self.filters = []
        self.favorites_filter = NameFilter(set(config['roms']['favorites']), log=False)
        self.machine_priority = config['roms'].get('priority', set())
        self.load()

    # Looks up the system from the given name
    @classmethod
    def from_json(cls, json: dict) -> None:
        name = json['system']

        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls(json)

        return cls(json)

    def load(self) -> None:
        # Load filters
        logging.info('Loading filters...')
        for filter_cls in self.static_filters:
            self.filters.append(filter_cls(config=self.config))

        for filter_cls in self.dynamic_filters:
            allowlist = self.config['roms']['allowlists'].get(filter_cls.name)
            blocklist = self.config['roms']['blocklists'].get(filter_cls.name)

            if allowlist:
                self.filters.append(filter_cls(set(allowlist), config=self.config))

            if blocklist:
                self.filters.append(filter_cls(set(blocklist), invert=True, config=self.config))

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
                if self.allow(machine):
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
        machines = []
        for title, grouped_machines in groups.items():
            # Find the highest-priority machine
            prioritized_machines = sorted(grouped_machines, key=self._sort_machines)
            machines.append(prioritized_machines[0])

            # Log all of the machines that were de-prioritized
            for machine in prioritized_machines[1:]:
                logging.info(f'[{machine.name}] Skip (PriorityFilter)')

        return machines

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
        except Exception as e:
            logging.error(f'[{machine.name}] Install failed')
            traceback.print_exc()

        return machine.is_valid_nonmerged

    # Whether this machine is allowed for install
    def allow(self, machine: Machine) -> bool:
        is_favorite = self.favorites_filter.allow(machine)
        return all((is_favorite and not filter.apply_to_favorites) or filter.allow(machine) for filter in self.filters)

    # Reset the visible set of machines
    def reset(self) -> None:
        for system_dir in self.dirs.values():
            system_dir.reset()

    # Enables the given list of machines so they're visible
    def enable(self, machines: List[Machine]) -> None:
        for machine in machines:
            # Machine is valid: Enable
            machine.clean()
            self.enable_machine(machine, self.dirs['all'])

            # Add to favorites
            if self.favorites_filter.allow(machine):
                self.enable_machine(machine, self.dirs['favorites'])

    # Enables the given machine in the given directory
    def enable_machine(self, machine: Machine, system_dir: SystemDir) -> None:
         machine.enable(system_dir)