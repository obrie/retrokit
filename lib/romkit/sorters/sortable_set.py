from __future__ import annotations

from romkit.models.machine import Machine

import logging
from collections import defaultdict
from enum import Enum
from typing import List, Optional

# Represents a sortable collection of machines
class SortableSet:
    def __init__(self,
        # Whether machine sorted has been enabeld
        enabled: bool = False,
        # Whether this collection should only allow a single machine to share a title
        single_title: bool = False,
    ) -> None:
        self.enabled = enabled
        self.single_title = single_title

        # Tracks machines associated with a specific group name
        self.groups = defaultdict(list)

        # Groups that have been explicitly overridden by filters
        self.overrides = set()

        # List of sort methods currently in use
        self.sorters = []

    # Builds a SortableSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_sorters: list) -> SortableSet:
        sortable_set = cls(
            enabled=json.get('enabled', False),
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
        self.overrides.add(machine.group_name)

    # Returns the list of all machines
    def all(self) -> List[Machine]:
        return [machine for machines in self.groups.values() for machine in machines]

    # Finalizes the prioritized set of machiens by performing any additional
    # post-processing, such as restricting the list of machines to prevent
    # multiple with the same title
    def prioritize(self) -> List[Machine]:
        if self.enabled:
            machines = []
            groups = self.groups.copy()

            # Add overrides
            for group_name in self.overrides:
                machines.extend(groups[group_name])
                del groups[group_name]

            # Add remaining prioritized groups
            machines.extend(self.__prioritize_groups(groups))

            if self.single_title:
                # Reduce the list further by only allowing a single machine/playlist
                # with a certain title
                groups_by_title = defaultdict(list)
                for machine in machines:
                    group = Machine.normalize(machine.disc_title)
                    groups_by_title[group].append(machine)

                machines = self.__prioritize_groups(groups_by_title)
        else:
            machines = [machine for machines in self.groups.values() for machine in machines]

        return machines

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
