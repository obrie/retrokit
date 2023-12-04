from __future__ import annotations

from collections import defaultdict

from metakit.attributes.base import BaseAttribute

class DiscsAttribute(BaseAttribute):
    name = 'discs'
    set_from_machine = True

    def get_from_machine(self, machine: Machine, grouped_machines: List[Machine]) -> List[str]:
        groups_by_disc_title = defaultdict(list)

        if not machine.has_playlist:
            return

        # Filter for machines with the same playlist name
        count = len({grouped_machine.disc_title for grouped_machine in grouped_machines if grouped_machine.playlist_name == machine.playlist_name})
        if count > 1:
            return count

    def validate(self, value: int) -> List[str]:
        if not isinstance(value, int) or value < 0:
            return [f'discs must be positive integer: {value}']
