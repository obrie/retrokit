from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on whether the machine has certain types of media
class MediaFilter(BaseFilter):
    name = 'media'

    def values(self, machine: Machine) -> Set[str]:
        return set(machine.media.keys())
