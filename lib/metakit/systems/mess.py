from __future__ import annotations

from metakit.systems.base import BaseSystem

class MessSystem(BaseSystem):
    name = 'mess'

    # Skip
    def update_metadata(self) -> None:
        pass
