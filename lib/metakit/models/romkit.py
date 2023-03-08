from __future__ import annotations

from typing import Set

from romkit.models.machine import Machine
from romkit.systems import BaseSystem

# Provides an interface to ROMKit data
class ROMKit:
    def __init__(self, config: dict) -> None:
        self.system = BaseSystem.from_json(config)

        self.names = set()
        self.titles = set()
        self.disc_titles = set()
        self.resolved_group_to_machine = {}

    # The names of the groups that were prioritized based on the
    # current ROMKit profile.  If we are updating based on a new DAT,
    # then this will represent the expected/target list of groups
    # that we want.
    @property
    def resolved_groups(self) -> Set[str]:
        return self.resolved_group_to_machine.keys()

    # The names of the machines that were prioritized based on the
    # current ROMKit profile
    @property
    def prioritized_machines(self) -> Set[Machine]:
        return self.system.prioritized_machines

    # Sorted set of machines that have been filtered by the system
    @property
    def machines(self) -> SortableSet:
        return self.system.machines

    # Iterates over each romset defined for the system
    def iter_romsets(self) -> Generator[None, ROMSet, None]:
        return self.system.iter_romsets()

    # Loads machines from the system's romsets in order to determine which set we
    # should be targeting when building the database
    def load(self, force: bool = False) -> None:
        if not self.system.load(force=force):
            return

        self.names.clear()
        self.titles.clear()
        self.disc_titles.clear()

        for machine in self.machines.all():
            self.names.add(machine.name)
            self.titles.add(machine.title)
            self.disc_titles.add(machine.disc_title)

        for machine in self.prioritized_machines:
            if '(' in machine.group_name:
                # Custom override -- use the machine name
                group = machine.name
            else:
                # If this machine has a parent, we prefer that -- manually make that the
                # real prioritized machine.
                if machine.parent_machine:
                    # Group this machine with its parent
                    machine.group_name = machine.parent_machine.group_name
                    self.machines.add(machine)

                    machine = machine.parent_machine

                # Use the machine's title since we may have chosen a different
                # machine instead of the original one
                group = machine.title

            # We need to make sure to only choose the first machine from a playlist
            # by sorting alphabetically.
            if group not in self.resolved_group_to_machine or machine.name < self.resolved_group_to_machine[group].name:
                self.resolved_group_to_machine[group] = machine

    # Finds all machines associated with a specific group name
    def find_machines_by_group(self, resolved_group: str) -> List[Machine]:
        prioritized_machine = self.resolved_group_to_machine.get(resolved_group)
        if prioritized_machine:
            return self.machines.groups.get(prioritized_machine.group_name, [])
        else:
            return []
