from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the description (this is the name for most systems)
class DescriptionFilter(BaseFilter):
    name = 'descriptions'

    def values(self, machine: Machine) -> Set[str]:
        return {f'{machine.description} ({machine.comment})'}


# Filter on flags (text between parens) from the description
class FlagFilter(BaseFilter):
    name = 'flags'

    def values(self, machine: Machine) -> Set[str]:
        return machine.flags
