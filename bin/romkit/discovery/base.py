import logging
import os
import re
import tempfile

# Provies a base class for discovery URL paths for romsets
class BaseDiscovery:
    name = None

    def __init__(self, romset, base_url, metadata_url_path, paths):
        self.romset = romset
        self.base_url = base_url
        self.metadata_url_path = metadata_url_path
        self.paths = paths
        self._mappings = None

    # Builds a ROMSet from the given JSON data
    @staticmethod
    def from_json(romset, json):
        return BaseDiscovery.from_name(json['type'])(
            romset,
            json['base'],
            json['metadata'],
            json['paths'],
        )

    # Looks up the discovery from the given name
    @staticmethod
    def from_name(name):
        for cls in BaseDiscovery.__subclasses__():
            if cls.name == name:
                return cls

        raise Exception(f'Invalid discovery: {name}')

    def mappings(self):
        if not self._mappings:
            self.load()
            self._mappings = {}

            for name, pattern in self.paths.items():
                self._mappings[name] = self.discover(re.compile(pattern))

        return self._mappings

    def download(self, *args, **kwargs):
        return self.romset.download(*args, **kwargs)

    def load(self):
        pass

    def discover(self, pattern):
        pass
