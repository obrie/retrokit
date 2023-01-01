from __future__ import annotations

from typing import List, Union

# Provides a base class for prioritizing machines that have been grouped together
class BaseSorter:
    name = None

    def __init__(self, setting: Union[str, List[str]], reverse: bool = False) -> None:
        if setting == 'ascending' or setting == 'descending':
            self.reverse = setting == 'descending'
            self.ordered = True
        else:
            self.setting = list(map(str.lower, setting))
            self.reverse = reverse
            self.ordered = False

    # Generates the key to use for sorting the machine with this sorter
    # 
    # If the sorter is ordered, then this is just the value associated with
    # the machine.  Otherwise, it'll be based on the index of the value within
    # the sorter setting.
    def sort_key(self, machine: Machine) -> Union[str, int]:
        machine_value = self.value(machine)

        if self.ordered or isinstance(machine_value, int):
            return machine_value
        else:
            # Default priority is lowest
            priority_index = len(self.setting)
            machine_value = machine_value.lower()

            for index, search_string in enumerate(self.setting):
                if search_string in machine_value:
                    # Found a matching priority string: track the index
                    priority_index = index
                    break

            return priority_index

    def value(self, machine: Machine) -> Union[str, int]:
        pass
