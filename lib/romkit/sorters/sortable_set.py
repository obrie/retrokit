from __future__ import annotations

from romkit.models.machine import Machine

import logging
from collections import defaultdict
from enum import Enum
from typing import List, Optional

# Represents a sortable collection of machines
class SortableSet:
    # A set of keys that have been reserved for special use in configuring
    # a sortable set.
    RESERVED_KEYS = {'group_by', 'order'}

    def __init__(self,
        # The list of properties to group by
        group_by: List[str] = [],
    ) -> None:
        self.group_by = group_by

        # Tracks machines associated with a specific group name
        self.groups = defaultdict(list)

        # Tracks overridden groups
        self.overrides = defaultdict(list)

        # List of sort methods currently in use
        self.sorters = []

    # Builds a SortableSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_sorters: list) -> SortableSet:
        sortable_set = cls(
            group_by=json.get('group_by', []),
        )

        sorters_by_name = {sorter.name: sorter for sorter in supported_sorters}

        # Either use a pre-defined order in which to process the sort strategies
        # or, by default, use the order in which the strategies were defined
        sorter_configs = {key: json[key] for key in json if key not in cls.RESERVED_KEYS}
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
            sortable_set.add_sorter(sorter(config, reverse=reverse))

        return sortable_set

    # Adds a new sorter
    def add_sorter(self, sorter) -> None:
        self.sorters.append(sorter)

    # Clears the current list of groups being tracked
    def clear(self) -> None:
        self.groups.clear()
        self.overrides.clear()

    # Associates the machine with the given group name
    def add(self, machine: Machine) -> None:
        self.groups[machine.group_name].append(machine)

    # Ignores all prioritization rules and prioritizes a machine within the
    # given group
    def override(self, machine: Machine) -> None:
        self.add(machine)
        self.overrides[machine.group_name].append(machine)

    # Returns the list of all machines
    def all(self) -> List[Machine]:
        return [machine for machines in self.groups.values() for machine in machines]

    # Finalizes the prioritized set of machiens by performing any additional
    # post-processing, such as restricting the list of machines to prevent
    # multiple with the same title
    def prioritize(self) -> List[Machine]:
        if 'group' in self.group_by:
            machines = []
            groups = self.groups.copy()

            # Add overrides, ignoring anything else that was in the same
            # override group
            for group_name, override_machines in self.overrides.items():
                machines.extend(override_machines)
                del groups[group_name]

            # Add remaining prioritized groups
            machines.extend(self.__prioritize_groups(groups))
        else:
            machines = self.all()

        for property_name in self.group_by:
            if property_name != 'group':
                machines = self.__prioritize_by_property(machines, property_name)

        return machines

    # Reduce a list of machines further by only allowing a single machine/playlist
    # with a certain property value
    def __prioritize_by_property(self, machines: List[Machine], property_name: str) -> List[Machine]:
        groups_by_value = defaultdict(list)
        for machine in machines:
            value = Machine.normalize(getattr(machine, property_name))
            groups_by_value[value].append(machine)

        return self.__prioritize_groups(groups_by_value)

    # Generates a list of prioritized machines for the given machine groupings.
    # 
    # If the highest prioritized machine is not part of a playlist, then only a
    # single machine from the group will be selected.
    # 
    # If the highest prioritized machine *is* part of a playlist, then only those
    # machines from the playlist will be selected.  Additionally, only a single
    # machine per disc will be selected for that playlist.
    def __prioritize_groups(self, groups: dict, process_playlists: bool = True) -> List[Machine]:
        machines = []

        # Sort and add machines
        for group in groups.values():
            group = self.__sort(group)
            top_machine = group[0]

            if process_playlists and top_machine.has_playlist:
                groups_by_disc_title = defaultdict(list)

                # Filter for machines with the same playlist name
                for machine in group:
                    if machine.has_playlist and machine.playlist_name == top_machine.playlist_name:
                        groups_by_disc_title[machine.disc_title].append(machine)
                    else:
                        logging.debug(f'[{machine.name}] Skip (PriorityFilter)')

                # Add only a single machine for each disc within the playlist
                machines.extend(self.__prioritize_groups(groups_by_disc_title, False))
            else:
                # Add just the top machine
                machines.append(top_machine)
                for machine in group[1:]:
                    logging.debug(f'[{machine.name}] Skip (PriorityFilter)')

        return machines

    # Sorts the list of machines based on the sorters in the order they
    # were defined
    def __sort(self, machines: List[Machine]) -> List[Machine]:
        for sorter in reversed(self.sorters):
            machines.sort(key=sorter.sort_key, reverse=sorter.reverse)

        return machines
