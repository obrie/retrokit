from __future__ import annotations

from romkit.discovery import BaseDiscovery
from romkit.models.machine import Machine
from romkit.processing.ruleset import Ruleset
from romkit.resources.downloader import Downloader
from romkit.resources.resource import ResourceTemplate
from romkit.util.dict_utils import slice_only

import logging
import lxml.etree
import tempfile
from typing import Dict, Generator, List, Optional

# Represents a reference ROM collection
class ROMSet:
    def __init__(self,
        system: BaseSystem,
        name: str,
        url: Optional[str] = None,
        resource_templates: Dict[str, ResourceTemplate] = {},
        emulators: List[str] = [],
        discovery: Optional[BaseDiscovery] = None,
        datlist: Optional[List[str]] = None,
        filters: Optional[Ruleset] = None,
        enabled: bool = True,
    ):
        self.system = system
        self.name = name
        self.url = url
        self.resource_templates = resource_templates
        self.emulators = emulators
        self.discovery = discovery
        self.filters = filters
        self.enabled = enabled
        self.downloader = system.downloader

        # Internal dat list for systems that don't have dat files
        if datlist:
            if type(datlist) is list:
                self.datlist = [{'name': name} for name in datlist]
            else:
                self.datlist = [{'name': name, **attrs} for name, attrs in datlist.items()]
        else:
            self.datlist = None

    # Builds a ROMSet from the given json data
    @classmethod
    def from_json(cls, json: dict, system: System, **kwargs) -> ROMSet:
        romset = cls(system=system, **slice_only(json, [
            'name',
            'url',
            'emulators',
            'datlist',
            'enabled',
        ]), **kwargs)

        if 'filters' in json:
            romset.filters = Ruleset.from_json(json['filters'], system.attributes)

        if 'discovery' in json:
            romset.discovery = BaseDiscovery.from_json(json['discovery'], downloader=romset.downloader)

        if 'resources' in json:
            romset.resource_templates = {
                name: ResourceTemplate.from_json(
                    config,
                    downloader=romset.downloader,
                    discovery=romset.discovery,
                    default_context={'url': romset.url},
                    stub=system.stub,
                )
                for name, config in json['resources'].items()
            }

        return romset

    # Only enabled resource templates
    @property
    def enabled_resource_templates(self) -> List[ResourceTemplate]:
        return {name: template for name, template in self.resource_templates.items() if template.enabled}

    # Checks whether this romset has been configured to be able to
    # download machines.  There must either be:
    # * An explicit url on the romset
    # * A url to be discovered
    @property
    def is_valid_for_download(self) -> bool:
        return self.url or self.discovery and not(self.discovery.has_missing_urls)

    # Whether this romset has defined the given resource
    def has_resource(self, name: str) -> bool:
        return name in self.enabled_resource_templates

    # Looks up the resource with the given name
    def resource(self, name: str, **context) -> Optional[Resource]:
        resource_template = self.enabled_resource_templates.get(name)
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

        if self.datlist is not None:
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
                    yield machine
                else:
                    logging.debug(f"[{element.get('name')}] Ignored (not installable)")
                
                element.clear()

    # Applies the given set of filters against this romset's list of machines.
    # 
    # This returns the machines that passed the filters and the reason why
    # the filter applied.
    def filter_machines(self, filters: Ruleset, metadata: Metadata) -> Dict[Machine, FilterReason]:
        results = {}
        possible_dependencies = {}

        for machine in self.iter_machines():
            # Update based on metadata database
            metadata.update(machine)

            if self.filters and not self.filters.match(machine):
                continue

            match_reason = filters.match(machine)
            if match_reason:
                possible_dependencies[machine.name] = machine
                results[machine] = match_reason
            elif not machine.is_clone or not machine.runnable:
                # We track all parent/bios/device machines in case they're needed as a dependency
                # in future machines.
                possible_dependencies[machine.name] = machine

        # All dependent machines (filtered machines + dependencies)
        dependent_machines = set(results.keys())
        for machine in dependent_machines.copy():
            dependent_machines.update(slice_only(possible_dependencies, machine.dependent_machine_names).values())

        # Set dependencies
        for machine in dependent_machines:
            machine.dependent_machines.update(slice_only(possible_dependencies, machine.dependent_machine_names))

        return results
