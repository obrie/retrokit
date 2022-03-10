from __future__ import annotations

from romkit.sorters.base import OrderingSorter, SubstringSorter

# Sort on presence of keywords in the name
class KeywordSorter(SubstringSorter):
    name = 'keywords'

    def value(self, machine: Machine) -> str:
        return f'{machine.description} ({machine.comment})'


# Sort on presence of flags in the name
class FlagSorter(SubstringSorter):
    name = 'flags'

    def value(self, machine: Machine) -> str:
        return machine.flags_str

# Sort on number of flag groups in the name
class FlagCountSorter(OrderingSorter):
    name = 'flags_count'

    def value(self, machine: Machine) -> int:
        return machine.flags_str.count('(')
