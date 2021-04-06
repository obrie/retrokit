import logging
import os
import tempfile

# Provies a base class for reducing the set of machines to install
class BaseFilter:
    name = None

    def __init__(self, config, filter_values=set(), invert=False, log=True):
        self.config = config
        self.filter_values = filter_values
        self.invert = invert
        self.log = log

        self.download()
        self.load()

    def allow(self, machine):
        if self.invert:
            allowed = not self.match(machine)
        else:
            allowed = self.match(machine)

        if not allowed and self.log:
            logging.info(f'[{machine.name}] Skip ({type(self).__name__})')

        return allowed

    def values(self, machine):
        return []

    def download(self):
        pass

    def load(self):
        pass

    def match(self, machine):
        pass


# Filter values must match exact values from the machine
class ExactFilter(BaseFilter):
    def match(self, machine):
        machine_values = self.values(machine)
        return any(self.filter_values & machine_values)


# Filter values can be just a substring of values from the machine
class SubstringFilter(BaseFilter):
    def match(self, machine):
        machine_values = self.values(machine)

        for machine_value in machine_values:
            if any(filter_value in machine_value for filter_value in self.filter_values):
                return True

        return False


# Filter on keywords in the description
class KeywordFilter(SubstringFilter):
    name = 'keywords'

    def values(self, machine):
        return {machine.description}


# Filter on flags (text between parens) from the description
class FlagFilter(SubstringFilter):
    name = 'flags'

    def values(self, machine):
        return machine.flags


# Filter on the machine name
class NameFilter(ExactFilter):
    name = 'names'

    def values(self, machine):
        return {machine.name}


# Filter on whether the machine is a clone of another
class CloneFilter(ExactFilter):
    name = 'clones'

    def values(self, machine):
        return {machine.parent_name is not None}


# Filter on the inpout controls
class ControlFilter(ExactFilter):
    name = 'controls'

    def values(self, machine):
        return machine.controls
