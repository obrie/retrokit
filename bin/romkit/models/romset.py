from __future__ import annotations

from romkit.auth import BaseAuth
from romkit.discovery import BaseDiscovery
from romkit.models import Machine
from romkit.resources import ResourceTemplate
from romkit.util import Downloader

import json
import logging
import lxml.etree
import tempfile
from typing import Dict, Generator, List, Optional

# Represents a reference ROM collection
class ROMSet:
    def __init__(self,
        system: BaseSystem,
        name: str,
        protocol: str,
        url: Optional[str],
        emulator: Optional[str],
        resource_templates: Dict[str, dict],
        auth: Optional[str] = None,
        discovery: Optional[dict] = None,
        datlist: Optional[List[str]] = None,
        context: dict = {},
    ):
        self.system = system
        self.name = name
        self.protocol = protocol
        self.url = url
        self.emulator = emulator
        self.downloader = Downloader(auth=auth)

        # Configure resources
        discovery = discovery and BaseDiscovery.from_json(discovery, downloader=self.downloader)
        self.resource_templates = {
            name: ResourceTemplate.from_json(
                config,
                downloader=self.downloader,
                discovery=discovery,
                default_context={'url': url},
            )
            for name, config in resource_templates.items()
        }

        # Internal dat list for systems that don't have dat files
        self.datlist = datlist

        self.machines = {}
        self.clone_parent_map = {}
        self.load()

    # Builds a ROMSet from the given JSON data
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> ROMSet:
        return cls(
            name=json['name'],
            protocol=json['protocol'],
            url=json.get('url'),
            emulator=json.get('emulator'),
            resource_templates=json['resources'],
            auth=json.get('auth'),
            discovery=json.get('discovery'),
            datlist=json.get('datlist'),
            **kwargs,
        )

    # Names of machines in this rom set
    @property
    def machine_names(self) -> List(str):
        return list(self.machines)

    # Looks up the machine with the given name
    def machine(self, name: str) -> Optional[Machine]:
        return self.machines.get(name)

    # Looks up the resource with the given name
    def resource(self, name: str, **context) -> Optional[Resource]:
        resource_template = self.resource_templates.get(name)
        if resource_template:
            return resource_template.render(**context)

    # Gets the DAT file for this romset
    @property
    def dat(self) -> Optional[Resource]:
        return self.resource('dat')

    # Gets the Clones DAT file for this romset
    @property
    def clones_dat(self) -> Optional[Resource]:
        return self.resource('clones')

    def load_clones(self) -> None:
        # Read in a custom group mapping from Retool
        custom_groups = {}
        with open(str(self.clones_dat.target_path.path)) as f:
            data = json.loads(f.read())
            for parent_name, clone_names in data['renames'].items():
                parent_group = Machine.title_from(Machine, parent_name)

                for (clone_name, other) in clone_names:
                    custom_groups[Machine.title_from(Machine, clone_name)] = parent_group

        # Find the clones
        groups = {}
        doc = lxml.etree.iterparse(str(self.dat.target_path.path), tag=('game'))
        for event, element in doc:
            name = element.get('name')
            group = Machine.title_from(Machine, name)
            if group in custom_groups:
                group = custom_groups[group]

            if group not in groups:
                groups[group] = []

            groups[group].append(name)
            element.clear()

        # Save the clones
        for group_title, names in groups.items():
            if len(names) > 1:
                prioritized_names = sorted(names, key=names.index)
                for name in prioritized_names[1:]:
                    self.clone_parent_map[name] = prioritized_names[0]

    # Loads downloaded data into this romset
    def load(self) -> None:
        if self.dat:
            self.dat.install()

        if self.clones_dat:
            self.clones_dat.install()
            self.load_clones()

    # Tracks the machine so that it can be referenced at a later point
    def track(self, machine: Machine) -> None:
        self.machines[machine.name] = machine

    # Removes the machine with the given name
    def remove(self, machine_name: str) -> None:
        if machine_name in self.machines:
            del self.machines[machine_name]

    # Looks up the machines in the dat file
    def iter_machines(self) -> Generator[None, Machine, None]:
        if self.datlist:
            # Read from an internal dat list
            for name in self.datlist:
                machine = Machine(self, name)
                machine.custom_context = self.system.context_for(machine)
                yield machine
        else:
            # Read from an external dat file
            doc = lxml.etree.iterparse(str(self.dat.target_path.path), tag=('game', 'machine'))
            for event, element in doc:
                if Machine.is_installable(element):
                    machine = Machine.from_xml(self, element)
                    machine.custom_context = self.system.context_for(machine)

                    # Attempt to set the parent/clone relationship if possible
                    if not machine.parent_name:
                        machine.parent_name = self.clone_parent_map.get(machine.name)

                    yield machine, element
                else:
                    logging.debug(f"[{element.get('name')}] Ignored (not installable)")
                
                element.clear()
