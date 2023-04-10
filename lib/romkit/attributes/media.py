from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Media associated with the machine, such as artwork
class MediaAttribute(BaseAttribute):
    metadata_name = 'media'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, media: Dict[str, str]) -> None:
        machine.media.update(media)

    def get(self, machine: Machine) -> Set[str]:
        return set(machine.media.keys())
