from romkit.auth import BaseAuth
from romkit.discovery import BaseDiscovery
from romkit.models import Machine
from romkit.resources import ResourceTemplate
from romkit.util import Downloader

import logging
import lxml.etree
import tempfile

# Represents a reference ROM collection
class ROMSet:
    def __init__(self, system, name, protocol, url, discovery, resources, emulator, auth, datlist=None):
        self.system = system
        self.name = name
        self.protocol = protocol
        self.url = url
        self.emulator = emulator
        self.downloader = Downloader(auth=auth)

        # Configure resources
        discovery = discovery and BaseDiscovery.from_json(self, discovery)
        self.resource_templates = {
            name: ResourceTemplate.from_json(config, discovery, self.downloader, {'url': url})
            for name, config in resources.items()
        }

        # Internal dat list for systems that don't have dat files
        self.datlist = datlist

        self.machines = {}
        self.load()

    # Builds a ROMSet from the given JSON data
    @staticmethod
    def from_json(system, json):
        return ROMSet(
            system,
            json['name'],
            json['protocol'],
            json.get('url'),
            json.get('discovery'),
            json['resources'],
            json['emulator'],
            json.get('auth'),
            json.get('datlist'),
        )

    # Looks up the machine with the given name
    def machine(self, name):
        return self.machines.get(name)

    # Looks up the resource with the given name
    def resource(self, name, **args):
        resource_template = self.resource_templates.get(name)
        if resource_template:
            return resource_template.get(**args)

    # Gets the DAT file for this romset
    @property
    def dat(self):
        return self.resource('dat')

    # Loads downloaded data into this romset
    def load(self):
        if self.dat:
            self.dat.install()

    # Tracks the machine so that it can be referenced at a later point
    def track(self, machine):
        self.machines[machine.name] = machine

    # Removes the machine with the given name
    def remove(self, machine_name):
        if machine_name in self.machines:
            del self.machines[machine_name]

    # Looks up the machines in the dat file
    def iter_machines(self):
        if self.datlist:
            # Read from an internal dat list
            for name in self.datlist:
                yield Machine(self, name)
        else:
            # Read from an external dat file
            doc = lxml.etree.iterparse(self.dat.target_path.path, tag=('game', 'machine'))
            _, root = next(doc)

            for event, element in doc:
                if Machine.is_installable(element):
                    yield Machine.from_xml(self, element)
                else:
                    logging.info(f"[{element.get('name')}] Ignored (not installable)")
                
                element.clear()

            root.clear()
