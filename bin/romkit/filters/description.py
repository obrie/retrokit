from __future__ import annotations

from romkit.filters.base import SubstringFilter

from typing import Set

# Filter on keywords in the description
class KeywordFilter(SubstringFilter):
    name = 'keywords'

    def values(self, machine: Machine) -> Set[str]:
        return {f'{machine.description} ({machine.comment})'}


# Filter on flags (text between parens) from the description
class FlagFilter(SubstringFilter):
    name = 'flags'

    def values(self, machine: Machine) -> Set[str]:
        return {machine.flags_str}
