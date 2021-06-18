from __future__ import annotations

import logging

# Provides a base class for reducing the set of machines to install
class BaseFilter:
    name = None
    apply_to_overrides = False
    normalize_values = True
    empty = set()

    def __init__(self,
        filter_values: set = set(),
        invert: bool = False,
        override: bool = False,
        log: bool = True,
        config: dict = {},
    ) -> None:
        self.filter_values = filter_values
        self.invert = invert
        self.override = override
        self.log = log
        self.config = config

        self.download()
        self.load()
        self.filter_values = set(self.normalize(self.filter_values))

    # Does this filter allow the given machine?
    def allow(self, machine: Machine) -> bool:
        if self.invert:
            allowed = not self.match(machine)
        else:
            allowed = self.match(machine)

        if not allowed and self.log:
            logging.debug(f'[{machine.name}] Skip ({type(self).__name__})')

        return allowed

    # Downloads any relevant data needed to run the filter
    def download(self) -> None:
        pass

    # Loads all of the relevant data needed to run the filter
    def load(self) -> None:
        pass

    # Looks up the list of values associated with the machine
    def values(self, machine: Machine) -> set:
        raise NotImplementedError

    # Do the filter values match the given machine?
    def match(self, machine: Machine) -> bool:
        raise NotImplementedError

    # Normalizes values so that lowercase/uppercase differences are
    # ignored during the matching process
    @classmethod
    def normalize(cls, values):
        if cls.normalize_values:
            return map(lambda value: value and value.lower(), values)
        else:
            return values


# Filter values must match exact values from the machine
class ExactFilter(BaseFilter):
    def match(self, machine: Machine) -> bool:
        machine_values = set(self.normalize(self.values(machine)))
        if not machine_values and None in self.filter_values:
            return True
        else:
            return len(self.filter_values & machine_values) > 0


# Filter values can be just a substring of values from the machine.
# 
# This is not case-sensitive.
class SubstringFilter(BaseFilter):
    def match(self, machine: Machine) -> bool:
        machine_values = set(self.normalize(self.values(machine)))
        if not machine_values and None in self.filter_values:
            return True

        for machine_value in machine_values:
            if any(filter_value and machine_value and filter_value in machine_value for filter_value in self.filter_values):
                return True

        return False
