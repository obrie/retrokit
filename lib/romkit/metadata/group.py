from __future__ import annotations

from romkit.metadata.base import BaseMetadata
from romkit.models.machine import Machine

# Provides a layer on top of predefined parent/clone relationships by grouping together
# additional titles not defined by a romset's dat.
class GroupMetadata(BaseMetadata):
    name = 'group'
    
    def load(self) -> None:
        self.groups = {}

        for key, machine_metadata in self.data.items():
            group = machine_metadata.get('group', key)
            self._map_group(key, group)

            # Add keys to merge into this group
            if 'merge' in machine_metadata:
                for key in machine_metadata['merge']:
                    self._map_group(key, group)

    # Maps the given key (a name or title) to a specific group
    # 
    # This maps both the raw key and a normalized version of the key in order to allow for
    # matching when there are minor differences in punctuation
    def _map_group(self, key: str, group: str) -> None:
        self.groups[key] = group
        self.groups[Machine.normalize(key)] = group

    def find_and_update(self, machine: Machine) -> None:
        # Priority:
        # * Machine-specific overrides (e.g. from a split), starting with machine's name
        # * Default grouping (title), starting with parent
        for key in [machine.name, machine.parent_name, machine.parent_disc_title, machine.parent_title, machine.disc_title, machine.title]:
            if not key:
                continue

            group_name = self.groups.get(key) or self.groups.get(Machine.normalize(key))
            if group_name:
                machine.group_name = group_name
                break
