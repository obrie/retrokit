from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Media associated with the machine, such as artwork
class MediaMetadata(BaseMetadata):
    name = 'media'

    def update(self, machine: Machine, media: Dict[str, str]) -> None:
            machine.media.update(media)
