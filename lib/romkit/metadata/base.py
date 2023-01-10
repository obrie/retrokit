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
        for key in [machine.name, machine.parent_name, machine.group_title]:
            if key and key in self.data:
                return self.data[key]

    # Loads all of the relevant data needed to machine attributes
    def load(self) -> None:
        pass

    # Looks up the metadata associated with the given machine and updates it with
    # the value associated with this type of metadata
    def find_and_update(self, machine: Machine) -> None:
        data = self.get_data(machine)
        if data:
            value = data.get(self.name)
            extended_value = data.get(f'+{self.name}')

            if value is not None or extended_value is not None:
                # Add to the original value (manual override)
                if extended_value:
                    if value:
                        value = value + extended_value
                    else:
                        value = extended_value

                self.update(machine, value)

    # Updates the machine with the given value for this type of metadata
    def update(self, machine: Machine, value) -> None:
        pass
