from __future__ import annotations

from romkit.metadata.external import ExternalMetadata
from romkit.models.machine import Machine

import json
import lxml.etree

# Parent/Clone metadata from Retool for system DATs that don't contain the
# information (typically redump DATs)
# 
# Format: JSON
class ParentMetadata(ExternalMetadata):
    name = 'parent'
    
    def load(self) -> None:
        self.custom_groups = {}
        self.group_parents = {}

        with self.install_path.open() as f:
            data = json.loads(f.read())
            for parent_name, clone_names in data['renames'].items():
                # We want to link parents by Disc instead of Game Title so that we
                # don't accidentally mark Disc 2 as having parent Disc 1
                parent_disc_title = Machine.title_from(parent_name, disc=True)

                # Map each clone to the parent via the disc title
                for (clone_name, other) in clone_names:
                    self.custom_groups[Machine.title_from(clone_name, disc=True)] = parent_disc_title

    def update(self, machine: Machine) -> None:
        group = self.custom_groups.get(machine.disc_title) or machine.disc_title

        # If the group isn't already tracked, then we know this is the primary parent
        if group not in self.group_parents:
            self.group_parents[group] = machine.name

        # Only attach a parent if it's different from this machine
        if not machine.parent_name and self.group_parents[group] != machine.name:
            machine.parent_name = self.group_parents[group]
