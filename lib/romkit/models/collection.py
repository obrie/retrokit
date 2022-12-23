from __future__ import annotations

# Represents a collection of machines based on a set of filters
class Collection:
    def __init__(self, name: str, filter_set: FilterSet) -> None:
        self.name = name
        self.filter_set = filter_set

    # Determines whether the given machine is a part of this collection
    def allow(self, machine: Machine) -> bool:
        return self.filter_set.allow(machine)
