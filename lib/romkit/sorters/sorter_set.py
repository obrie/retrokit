from __future__ import annotations

from romkit.models.machine import Machine

import logging
from enum import Enum
from typing import List, Optional

# Represents a sortable collection of machines
class SorterSet:
    def __init__(self,
        # Whether machine sorted has been enabeld
        enabled: bool = True,
        # Whether this collection should only allow a single machine to share a title
        single_title: bool = False,
    ) -> None:
        self.enabled = enabled
        self.single_title = single_title

        # Mapping of group => highest prioritized machine
        self.groups = {}

        # List of groups that we've explicitly overridden
        self.overrides = set()

        # List of sort methods currently in use
        self.sorters = []

    # Builds a SorterSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_sorters: list) -> SorterSet:
        sorter_set = cls(
            enabled=json.get('enabled', True),
            single_title=json.get('single_title', False),
        )

        sorters_by_name = {sorter.name: sorter for sorter in supported_sorters}

        # Either use a pre-defined order in which to process the sort strategies
        # or, by default, use the order in which the strategies were defined
        sorter_configs = {key: json[key] for key in json if key != 'enabled' and key != 'order'}
        sorter_config_names = json.pop('order', sorter_configs.keys())

        for sorter_config_name in sorter_config_names:
            # Ignore everything after "|" which is used to allow multiple versions
            # of the same sorter to be used
            sorter_name = sorter_config_name.split('|')[0]

            if sorter_name[0] == '!':
                sorter_name = sorter_name[1:]
                reverse = True
            else:
                reverse = False

            # Lookup and create the sorter
            sorter = sorters_by_name[sorter_name]
            config = sorter_configs[sorter_config_name]
            sorter_set.append(sorter(config, reverse=reverse))

        return sorter_set

    # Number of sorters defined
    @property
    def length(self) -> int:
        return len(self.sorters)

    # Adds a new sorter
    def append(self, sorter) -> None:
        self.sorters.append(sorter)

    @property
    def machines(self) -> Set[Machine]:
        return set(self.groups.values())

    # Clears the current list of groups being tracked
    def clear(self) -> None:
        self.groups.clear()
        self.overrides.clear()

    # Prioritizes the machine with the given group name
    def prioritize(self, machine: Machine, group: Optional[str] = None) -> None:
        group = group or machine.group_name
        existing = self.groups.get(group)

        if not existing:
            # First time we've seen this group: make the machine the default
            self.groups[group] = machine
        elif group not in self.overrides:
            # Decide which of the two machines to install based on the
            # predefined priority order
            prioritized_machines = self.__sort([existing, machine])
            self.groups[group] = prioritized_machines[0]
            logging.debug(f'[{prioritized_machines[1].name}] Skip (PriorityFilter)')

    # Ignores all prioritization rules and explicitly assigns a machine to the
    # given group
    def override(self, machine: Machine, group: Optional[str] = None) -> None:
        group = group or machine.group_name
        self.groups[group] = machine
        self.overrides.add(group)

    # Finalizes the prioritized set of machiens by performing any additional
    # post-processing, such as restricting the list of machines to prevent
    # multiple with the same title
    def finalize(self) -> None:
        if self.single_title:
            groups = self.groups.copy()
            self.clear()
            for group, machine in groups.items():
                new_group = Machine.normalize(machine.disc_title)
                if group in self.overrides:
                    self.override(machine, new_group)
                else:
                    self.prioritize(machine, new_group)

    # Sorts the list of machines based on the sorters in the order they
    # were defined
    def __sort(self, machines: List[Machine]) -> List[Machine]:
        for sorter in reversed(self.sorters):
            machines.sort(key=sorter.sort_key, reverse=sorter.reverse)

        return machines
