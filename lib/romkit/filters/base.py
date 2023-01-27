from __future__ import annotations

import logging
import re

from enum import Enum

class FilterMatchType(Enum):
    EXACT = 'exact'
    SUBSTRING = 'substring'
    PATTERN = 'pattern'


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
        match_type: FilterMatchType = FilterMatchType.EXACT,
        log: bool = True,
        config: dict = {},
    ) -> None:
        self.filter_values = filter_values
        self.invert = invert
        self.override = override
        self.match_type = match_type
        self.log = log
        self.config = config

        self.load()
        if self.match_type == FilterMatchType.PATTERN:
            # Compile to regular expressions
            self.filter_values = set([value and re.compile(value) for value in self.normalize(self.filter_values)])
        else:
            # Normalize the values (lowercase)
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

    # Loads all of the relevant data needed to run the filter
    def load(self) -> None:
        pass

    # Looks up the list of values associated with the machine
    def values(self, machine: Machine) -> set:
        raise NotImplementedError

    # Do the filter values match the given machine?
    def match(self, machine: Machine) -> bool:
        machine_values = set(self.normalize(self.values(machine)))
        if not machine_values and None in self.filter_values:
            return True

        if self.match_type == FilterMatchType.EXACT:
            # Match the exact value as it was normalized
            return len(self.filter_values & machine_values) > 0
        elif self.match_type == FilterMatchType.SUBSTRING:
            # Match substring
            for machine_value in machine_values:
                # Add quotes to allow for exact matching
                if machine_value:
                    machine_value = f'"{machine_value}"'

                if any(filter_value and machine_value and filter_value in machine_value for filter_value in self.filter_values):
                    return True
        else:
            # Match regular expression
            for machine_value in machine_values:
                if any(filter_value and machine_value and filter_value.match(machine_value) for filter_value in self.filter_values):
                    return True

    # Normalizes values so that lowercase/uppercase differences are
    # ignored during the matching process
    @classmethod
    def normalize(cls, values):
        if cls.normalize_values:
            return map(lambda value: value and value.lower(), values)
        else:
            return values
