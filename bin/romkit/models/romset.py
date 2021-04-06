from romkit.auth import BaseAuth
from romkit.build import BaseBuild
from romkit.formats import BaseFormat
from romkit.models import Machine
from romkit.util import Downloader

import logging
import lxml.etree
import os
import tempfile
from pathlib import Path
from urllib.parse import quote

# Represents a reference ROM collection
class ROMSet:
    def __init__(self, system, name, protocol, url_templates, file_templates, build, format, emulator, auth):
        self.system = system
        self.name = name
        self.protocol = protocol
        self.url_templates = url_templates
        self.file_templates = file_templates
        self.build = BaseBuild.from_name(build)()
        self.format = BaseFormat.from_name(format)()
        self.emulator = emulator
        self.downloader = Downloader(auth=auth)
        self.machines = {}

        self.load()

    # Builds a ROMSet from the given JSON data
    @staticmethod
    def from_json(system, json):
        return ROMSet(
            system,
            json['name'],
            json['protocol'],
            json['urls'],
            json['files'],
            json['build'],
            json['format'],
            json['emulator'],
            json.get('auth'),
        )

    # Builds a URL for an asset in this romset
    def build_url(self, asset_name, **args):
        encoded_args = {}
        for key, value in args.items():
            encoded_args[key] = quote(value)

        return self.url_templates[asset_name].format(
            base=self.url_templates['base'],
            **encoded_args,
        )

    # Builds the local filepath for an asset in this romset
    def build_filepath(self, asset_name, **args):
        return self.file_templates[asset_name].format(
            home=str(Path.home()),
            **args,
        )

    # Looks up the machine with the given name
    def machine(self, name):
        return self.machines.get(name)

    # Downloads files needed for this romset
    def download(self, *args, **kwargs):
        self.downloader.get(*args, **kwargs)

    # Loads downloaded data into this romset
    def load(self):
        self.download(self.build_url('dat'), f"{tempfile.gettempdir()}/{self.system.name}-{self.name}.dat")

    # Tracks the machine so that it can be referenced at a later point
    def track(self, machine):
        self.machines[machine.name] = machine

    # Removes the machine with the given name
    def remove(self, machine_name):
        if machine_name in self.machines:
            del self.machines[machine_name]

    # Looks up the machines in the dat file
    def iter_machines(self):
        doc = lxml.etree.iterparse(f"{tempfile.gettempdir()}/{self.system.name}-{self.name}.dat", tag=('game', 'machine'))
        _, root = next(doc)

        for event, element in doc:
            if Machine.is_installable(element):
                yield Machine.from_xml(self, element)
            else:
                logging.info(f"[{element.get('name')}] Ignored (not installable)")
            
            element.clear()

        root.clear()
