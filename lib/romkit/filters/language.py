from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on languages
class LanguageFilter(ExactFilter):
    name = 'languages'

    def values(self, machine: Machine) -> Set[str]:
        return machine.languages
