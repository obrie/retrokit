from __future__ import annotations

from romkit.metadata.base import BaseMetadata
from romkit.models.machine import Machine

# Parent/Clone metadata from Retool for system DATs that don't contain the
# information (typically redump DATs)
# 
# Format: JSON
class ParentsMetadata(BaseMetadata):
    name = 'parents'
    
    def load(self) -> None:
        self.custom_groups = {}
        self.group_parents = {}
        self.autodetect = self.config.get('autodetect')

        for key, machine_metadata in self.data.items():
            if 'parents' not in machine_metadata:
                continue

            for parent_data in machine_metadata['parents']:
                parent_name = parent_data['name']
                clone_disc_titles = parent_data.get('clones')

                parent_disc_title = Machine.title_from(parent_name, disc=True)
                self.group_parents[parent_disc_title] = parent_name
                
                if clone_disc_titles:
                    for clone_disc_title in clone_disc_titles:
                        self.custom_groups[clone_disc_title] = parent_disc_title

    def find_and_update(self, machine: Machine) -> None:
        group = self.custom_groups.get(machine.disc_title) or machine.disc_title

        # If the group isn't already tracked, then we know this is the primary parent
        if self.autodetect and group not in self.group_parents:
            self.group_parents[group] = machine.parent_name or machine.name

        # Only attach a parent if it's different from this machine
        new_parent_name = self.group_parents.get(group)
        if not machine.parent_name and new_parent_name and new_parent_name != machine.name:
            machine.parent_name = new_parent_name
