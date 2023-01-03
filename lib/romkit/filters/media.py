from __future__ import annotations

from romkit.filters.base import ExactFilter

from typing import Set

# Filter on whether the machine has certain types of media
class MediaFilter(ExactFilter):
    name = 'media'

    def values(self, machine: Machine) -> Set[str]:
        return set(machine.media.keys())
