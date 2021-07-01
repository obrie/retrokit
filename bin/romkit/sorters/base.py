from __future__ import annotations

from typing import List

# Provides a base class for prioritizing machines in the same parent/clone grou
class BaseSorter:
    name = None

    def __init__(self, setting) -> None:
        self.setting = setting

    # By default, we never reverse the sort order.  This can be overridden for
    # sorters that explicitly define the ordering.
    @property
    def reverse(self) -> bool:
        return False


# Sorts based on the presence of a substring in a value from the machine
class SubstringSorter(BaseSorter):
    def __init__(self, setting: List[str]) -> None:
        self.setting = list(map(str.lower, setting))

    def sort_key(self, machine: Machine) -> int:
        # Default priority is lowest
        priority_index = len(self.setting)
        machine_value = self.value(machine).lower()

        for index, search_string in enumerate(self.setting):
            if search_string in machine_value:
                # Found a matching priority string: track the index
                priority_index = index
                break

        return priority_index

# Sorts based on alphabetical ordering in an ascending or descending fashion
class OrderingSorter(BaseSorter):
    @property
    def reverse(self) -> bool:
        return self.setting == 'descending'

    def sort_key(self, machine: Machine) -> str:
        return self.value(machine)
