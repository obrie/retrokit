from romkit.filters.base import FlagFilter, KeywordFilter, NameFilter, CloneFilter, ControlFilter
from romkit.models import Machine, ROMSet

import logging
import os
from pathlib import Path

class BaseSystem:
    name = 'base'
    user_filters = [
        CloneFilter,
        KeywordFilter,
        FlagFilter,
        ControlFilter,
        NameFilter,
    ]
    auto_filters = []

    def __init__(self, config):
        self.config = config
        self.file_templates = config['roms']['files']
        self.filters = []
        self.favorites_filter = NameFilter(config, set(config['roms']['favorites']), log=False)
        self.machine_priority = config['roms'].get('priority', set())
        self.load()

    def build_filepath(self, dir_name, asset_name, **args):
        dirpath = self.config['roms']['dirs'][dir_name]
        return self.file_templates[asset_name].format(dir=dirpath, **args)

    # Looks up the system from the given name
    def from_name(name):
        for cls in BaseSystem.__subclasses__():
            if cls.name == name:
                return cls

        return BaseSystem

    def iter_romsets(self):
        # Load romsets
        for romset_config in self.config['romsets']:
            yield ROMSet.from_json(self, romset_config)


    def load(self):
        # Load filters
        logging.info('--- Loading filters ---')
        for filter_cls in self.auto_filters:
            self.filters.append(filter_cls(self.config))

        for filter_cls in self.user_filters:
            allowlist = self.config['roms']['allowlists'].get(filter_cls.name)
            blocklist = self.config['roms']['blocklists'].get(filter_cls.name)

            if allowlist:
                self.filters.append(filter_cls(self.config, set(allowlist)))

            if blocklist:
                self.filters.append(filter_cls(self.config, set(blocklist), True))

    def list(self):
        # Filter and group by the base name (so, for example, multiple
        # games with different revisions will be grouped together)
        groups = {}

        for romset in self.iter_romsets():
            # Machines that are installable or required by installable machines
            machines_to_track = set()

            for machine in romset.iter_machines():
                if self.allow(machine):
                    machines_to_track.update(machine.dependent_machine_names)
                    machine.track()

                    # Group the machine
                    base_name = machine.base_name
                    if base_name not in groups:
                        groups[base_name] = []
                    groups[base_name].append(machine)
                elif not machine.is_clone:
                    # We track all parent/bios machines in case they're needed as a dependency
                    # in future machines
                    machine.track()

            # Free memory by removing machines we didn't need to keep
            for name in list(romset.machines):
                if name not in machines_to_track:
                    romset.remove(name)

        # Prioritize the machines within each group
        machines = []
        for base_name, grouped_machines in groups.items():
            prioritized_machines = sorted(grouped_machines, key=self._sort_machines)
            machines.append(prioritized_machines[0])

            for machine in prioritized_machines[1:]:
                logging.info(f'[{machine.name}] Skip (PriorityFilter)')

        return machines

    # Sorts machines based on a predefined priority ordering.
    # 
    # If two machines have the same priority, the machine with the shortest name
    # is chosen.
    def _sort_machines(self, machine):
        priority_index = len(self.machine_priority)
        for index, search_string in enumerate(self.machine_priority):
            if search_string in machine.flags_str:
                priority_index = index
                break

        return (priority_index, len(machine.name))

    # Installs all of the filtered machines
    def install(self):
        # Filter
        machines = self.list()

        # Install
        for machine in machines:
            machine.install()

        # Find valid machines
        valid_machines = filter(Machine.is_valid_nonmerged, machines)

        # Reset
        for dirname, dirpath in self.config['roms']['dirs'].items():
            if Path(dirpath).is_dir():
                for filename in os.listdir(dirpath):
                    filepath = os.path.join(dirpath, filename)
                    if os.path.islink(filepath):
                        os.unlink(filepath)

        # Enable
        for machine in valid_machines:
            # Machine is valid: Enable
            machine.enable('all')

            # Add to favorites
            if self.favorites_filter.allow(machine):
                machine.enable('favorites')

    # Whether this machine is allowed for install
    def allow(self, machine):
        return self.favorites_filter.allow(machine) or all(filter.allow(machine) for filter in self.filters)
