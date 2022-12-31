from __future__ import annotations

from romkit.metadata.base import BaseMetadata
from romkit.models.machine import Machine

# Provides a layer on top of predefined parent/clone relationships by grouping together
# additional titles not defined by a romset's dat.
class GroupMetadata(BaseMetadata):
    name = 'group'
    
    def load(self) -> None:
        self.groups = {}

        for title, machine_metadata in self.data.items():
            self._map_group(title, title)

            group_metadata = machine_metadata.get('group')
            if not group_metadata:
                continue

            # Add keys to merge into this group
            if 'merge' in group_metadata:
                for grouped_key in group_metadata['merge']:
                    self._map_group(grouped_key, title)

            # Add new groups to split off from the base title
            if 'split' in group_metadata:
                for name in group_metadata['split']:
                    # Prepend the machine title if only flags were specified
                    if name[0] == '(':
                        name = f"{title} {name}"

                    self._map_group(name, name)

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
        for key in [machine.name, machine.parent_name, machine.disc_title, machine.parent_disc_title, machine.parent_title, machine.title]:
            if not key:
                continue

            group_name = self.groups.get(key) or self.groups.get(Machine.normalize(key))
            if group_name:
                machine.group_name = group_name
                break
