from __future__ import annotations

from enum import Enum
from typing import List

# Represents a collection of machine sorters
class SorterSet:
    def __init__(self) -> None:
        self.sorters = []

    # Builds a SorterSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_sorters: list) -> SorterSet:
        sorter_set = cls()
        sorters_by_name = {sorter.name: sorter for sorter in supported_sorters}

        # Either use a pre-defined order in which to process the sort strategies
        # or, by default, use the order in which the strategies were defined
        sorter_config_names = json.pop('order', json.keys())

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
            config = json[sorter_config_name]
            sorter_set.append(sorter(config, reverse=reverse))

        return sorter_set

    # Number of sorters defined
    @property
    def length(self) -> int:
        return len(self.sorters)

    # Adds a new sorter
    def append(self, sorter) -> None:
        self.sorters.append(sorter)

    # Sorts the list of machines based on the sorters in the order they
    # were defined
    def sort(self, machines: List[Machine]) -> List[Machine]:
        for sorter in reversed(self.sorters):
            machines.sort(key=sorter.sort_key, reverse=sorter.reverse)

        return machines
