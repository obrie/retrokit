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
        sorter_names = json.pop('order', json.keys())

        for sorter_name in sorter_names:
            sorter = sorters_by_name[sorter_name]
            setting = json[sorter_name]

            sorter_set.append(sorter(setting))

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
