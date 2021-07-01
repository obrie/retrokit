from __future__ import annotations

from romkit.sorters.base import SubstringSorter

# Sort on presence of keywords in the name
class KeywordSorter(SubstringSorter):
    name = 'keywords'

    def value(self, machine: Machine) -> str:
        return machine.title


# Sort on presence of flags in the name
class FlagSorter(SubstringSorter):
    name = 'flags'

    def value(self, machine: Machine) -> str:
        return machine.flags_str
