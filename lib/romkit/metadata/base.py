from __future__ import annotations

from romkit.models.machine import Machine

# Provides a base class for loading machine-level metadata outside the system dat
class BaseMetadata:
    name = None
    default_context = {}

    def __init__(self, data: dict = {}, config: dict = {}) -> None:
        self.data = data
        self.config = config
        self.load()

    # Looks up the data associated with the given machine.  The following machine
    # attributes will be used to find a matching key (in order of priority):
    # 
    # * Name
    # * Parent name
    # * Group title
    # 
    # The first match will be returned.
    def get_data(self, machine: Machine):
        return self.data.get(machine.name) or self.data.get(machine.parent_name) or self.data.get(machine.group_title)

    # Loads all of the relevant data needed to machine attributes
    def load(self) -> None:
        pass

    # Looks up the metadata associated with the given machine and updates it with
    # the value associated with this type of metadata
    def find_and_update(self, machine: Machine) -> None:
        data = self.get_data(machine)
        if data:
            value = data.get(self.name)
            if value:
                self.update(machine, value)

    # Updates the machine with the given value for this type of metadata
    def update(self, machine: Machine, value) -> None:
        pass
