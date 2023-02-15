from __future__ import annotations

from romkit.auth import BaseAuth
from romkit.discovery import BaseDiscovery
from romkit.filters import FilterSet
from romkit.models.machine import Machine
from romkit.resources.resource import ResourceTemplate
from romkit.util import Downloader

import logging
import lxml.etree
import tempfile
from typing import Dict, Generator, List, Optional

# Represents a reference ROM collection
class ROMSet:
    def __init__(self,
        system: BaseSystem,
        name: str,
        protocol: Optional[str],
        url: Optional[str],
        resource_templates: Dict[str, dict],
        emulators: Optional[List[str]] = None,
        auth: Optional[str] = None,
        discovery: Optional[dict] = None,
        datlist: Optional[List[str]] = None,
        downloads: Optional[dict] = None,
        filters: Optional[dict]  = None,
        enabled: bool = True,
        context: dict = {},
    ):
        self.system = system
        self.name = name
        self.protocol = protocol
        self.url = url
        self.emulators = emulators or []
        self.downloader = Downloader(auth=auth, **downloads)
        self.filter_set = FilterSet.from_json(filters or {}, system.config, system.supported_filters)
        self.enabled = enabled

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
        if datlist:
            if type(datlist) is list:
                self.datlist = [{'name': name} for name in datlist]
            else:
                self.datlist = [{'name': name, **attrs} for name, attrs in datlist.items()]
        else:
            self.datlist = None

        self.load()

    # Builds a ROMSet from the given JSON data
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> ROMSet:
        return cls(
            name=json['name'],
            protocol=json.get('protocol'),
            url=json.get('url'),
            resource_templates=json['resources'],
            emulators=json.get('emulators'),
            auth=json.get('auth'),
            discovery=json.get('discovery'),
            datlist=json.get('datlist'),
            filters=json.get('filters'),
            enabled=json.get('enabled', True),
            **kwargs,
        )

    # Whether this romset has defined the given resource
    def has_resource(self, name: str) -> bool:
        return name in self.resource_templates

    # Looks up the resource with the given name
    def resource(self, name: str, **context) -> Optional[Resource]:
        resource_template = self.resource_templates.get(name)
        if resource_template:
            return resource_template.render(**context)

    # Gets the DAT file for this romset
    @property
    def dat(self) -> Optional[Resource]:
        return self.resource('dat')

    # Loads downloaded data into this romset
    def load(self) -> None:
        if self.dat and self.enabled:
            self.dat.install()

    # Looks up the machines in the dat file
    def iter_machines(self) -> Generator[None, Machine, None]:
        if not self.enabled:
            return

        if self.datlist:
            # Read from an internal dat list
            for machine_attrs in self.datlist:
                machine = Machine.from_dict(self, machine_attrs)
                yield machine
        else:
            # Read from an external dat file
            doc = lxml.etree.iterparse(str(self.dat.target_path.path), tag=('game', 'machine'))
            for event, element in doc:
                if Machine.is_installable(element):
                    machine = Machine.from_xml(self, element)
                    if self.filter_set.allow(machine):
                        yield machine
                else:
                    logging.debug(f"[{element.get('name')}] Ignored (not installable)")
                
                element.clear()

    # Applies the given set of filters against this romset's list of machines.
    # 
    # This returns the machines that passed the filters and the reason why
    # the filter applied.
    def filter_machines(self, filter_set: FilterSet, metadata_set: MetadataSet) -> Dict[Machine, FilterReason]:
        results = {}
        dependent_machines = {}

        for machine in self.iter_machines():
            # Update based on metadata database
            metadata_set.update(machine)

            allow_reason = filter_set.allow(machine)
            if allow_reason:
                dependent_machines[machine.name] = machine
                results[machine] = allow_reason
            elif not machine.is_clone:
                # We track all parent/bios/device machines in case they're needed as a dependency
                # in future machines.
                dependent_machines[machine.name] = machine

        # Update the filtered machines with the dependent machines they need
        # in order to run
        for machine in results.keys():
            for dependency_name in machine.dependent_machine_names:
                if dependency_name in dependent_machines:
                    machine.dependent_machines[dependency_name] = dependent_machines[dependency_name]

        return results
