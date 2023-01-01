from __future__ import annotations

from romkit.sorters.base import BaseSorter

# Sort on name
class NameSorter(BaseSorter):
    name = 'name'

    def value(self, machine: Machine) -> str:
        return machine.name


# Sort on name length
class NameLengthSorter(BaseSorter):
    name = 'name_length'

    def value(self, machine: Machine) -> int:
        return len(machine.name)


# Sort on title
class TitleSorter(BaseSorter):
    name = 'title'

    def value(self, machine: Machine) -> str:
        return machine.title


# Sort on title length
class TitleLengthSorter(BaseSorter):
    name = 'title_length'

    def value(self, machine: Machine) -> int:
        return len(machine.title)
