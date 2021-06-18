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
                parent_group = Machine.title_from(Machine, parent_name)

                for (clone_name, other) in clone_names:
                    self.custom_groups[Machine.title_from(Machine, clone_name)] = parent_group

    def update(self, machine: Machine) -> None:
        group = self.custom_groups.get(machine.title) or machine.title
        if group not in self.group_parents:
            self.group_parents[group] = machine.name

        if not machine.parent_name and self.group_parents[group] != machine.name:
            machine.parent_name = self.group_parents[group]
