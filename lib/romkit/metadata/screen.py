from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Metadata related to the screen
class ScreenMetadata(BaseMetadata):
    name = 'screen'

    def update(self, machine: Machine, screen: dict) -> None:
        if 'orientation' in screen:
            machine.orientation = screen['orientation']
