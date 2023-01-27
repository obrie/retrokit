from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on languages
class LanguageFilter(BaseFilter):
    name = 'languages'

    def values(self, machine: Machine) -> Set[str]:
        return machine.languages
