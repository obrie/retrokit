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
        for sorter_name, setting in json.items():
            sorter_set.append(sorters_by_name[sorter_name](setting))

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
