from __future__ import annotations

from romkit.filters.base import SubstringFilter

# Filter on keywords in the description
class KeywordFilter(SubstringFilter):
    name = 'keywords'

    def values(self, machine: Machine) -> set:
        return {machine.description}


# Filter on flags (text between parens) from the description
class FlagFilter(SubstringFilter):
    name = 'flags'

    def values(self, machine: Machine) -> set:
        return machine.flags
