from __future__ import annotations

import logging
import re

from enum import Enum

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
        self.invert = invert
        self.override = override
        self.log = log
        self.config = config

        self.load()

        self.exact_filter_values = set()
        self.pattern_filter_values = set()

        # Normalize the values:
        # * Lowercase all
        # * Compile regular expressions when shape is /...
        for filter_value in self.normalize(filter_values):
            # Skip values being used as comments
            if isinstance(filter_value, str) and filter_value[0] == '#':
                continue

            if isinstance(filter_value, str) and filter_value and filter_value[0] == '/':
                # Compile to regular expression
                self.pattern_filter_values.add(re.compile(filter_value[1:]))
            else:
                self.exact_filter_values.add(filter_value)

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

        if not machine_values and None in self.exact_filter_values:
            # Empty allowed
            return True
        elif not self.exact_filter_values.isdisjoint(machine_values) > 0:
            # Exact value matched
            return True
        elif self.pattern_filter_values:
            # Look for pattern
            for machine_value in machine_values:
                if machine_value and any(pattern.search(machine_value) for pattern in self.pattern_filter_values):
                    return True

        return False

    # Normalizes values so that lowercase/uppercase differences are
    # ignored during the matching process
    @classmethod
    def normalize(cls, values):
        if cls.normalize_values:
            return map(lambda value: value and value.lower(), values)
        else:
            return values
