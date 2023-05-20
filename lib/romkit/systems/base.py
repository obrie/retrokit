from __future__ import annotations

from romkit.attributes import __all_attributes__
from romkit.models.collection_set import CollectionSet
from romkit.models.machine import Machine
from romkit.models.romset import ROMSet
from romkit.processing import Metadata, Ruleset, RuleMatchReason, SortableSet
from romkit.systems.system_dir import SystemDir
from romkit.util import Downloader
from romkit.util.dict_utils import deepmerge

import logging
import os
import requests
import shlex
import time
import traceback
from collections import defaultdict
from copy import copy
from pathlib import Path
from typing import Dict, Generator, List, Optional, Tuple

# Maximum number of times we'll attempt to install a machine
INSTALL_MAX_ATTEMPTS = os.getenv('INSTALL_MAX_ATTEMPTS', 3)
INSTALL_RETRY_WAIT_TIME = os.getenv('INSTALL_RETRY_WAIT_TIME', 30) # seconds

class BaseSystem:
    name = 'base'

    def __init__(self,
        name: str,
        stub: bool = False,
        rom_id_type: str = 'crc',
        downloader: Downloader = Downloader.instance(),
        favorites_rules: Ruleset = Ruleset(default_on_empty=None, log=False),
        collections: CollectionSet = CollectionSet(),
        filters: Ruleset = Ruleset(),
        dirs: List[SystemDir] = [],
    ) -> None:
        self.name = name
        self.stub = stub
        self.rom_id_type = rom_id_type
        self.downloader = downloader
        self.favorites_rules = favorites_rules
        self.collections = collections
        self.filters = filters
        self.dirs = dirs
        self.file_templates = {}
        self.romsets = []

        # Set up attributes
        self.attributes = [attribute_cls() for attribute_cls in __all_attributes__]
        self.metadata = Metadata(self.attributes)
        for attribute in self.attributes:
            self.reconfigure_attribute(attribute.primary_name)

        # Track machines that have been filtered / prioritized
        self.machines = SortableSet()
        self.prioritized_machines = []
        self._loaded = False

    # Looks up the system from the given name
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> None:
        name = json['system']
        system_cls = cls

        for subcls in cls.__subclasses__():
            if subcls.name == name:
                system_cls = subcls

        json = defaultdict(dict, json)

        options = {}
        if 'stub' in json['roms']:
            options['stub'] = json['roms']['stub']
        if 'id' in json['roms']:
            options['rom_id_type'] = json['roms']['id']
        if 'downloads' in json:
            options['downloader'] = Downloader.from_json(json['downloads'])

        system = system_cls(name=name, **options, **kwargs)

        # Metadata
        if 'metadata' in json:
            system.metadata = Metadata.from_json(json['metadata'], system.attributes)

        # ROM settings
        if 'favorites' in json['roms']:
            system.favorites_rules = Ruleset.from_json(json['roms']['favorites'], system.attributes, default_on_empty=None, log=False)

        if 'collections' in json['roms']:
            system.collections = CollectionSet.from_json(json['roms']['collections'], system.attributes)

        if 'filters' in json['roms']:
            system.filters = Ruleset.from_json(json['roms']['filters'], system.attributes)

        if 'priority' in json['roms']:
            system.machines = SortableSet.from_json(json['roms']['priority'], system.attributes)

        if 'romsets' in json:
            for romset_name, romset_config in json['romsets'].items():
                system.romsets.append(ROMSet.from_json({**romset_config, 'name': romset_name}, system))

        # Install files/directories
        if 'files' in json['roms']:
            system.file_templates = json['roms']['files']

        if 'dirs' in json['roms']:
            system.dirs = [
                SystemDir(
                    dir_config['path'],
                    Ruleset.from_json(dir_config.get('filters', {}), system.attributes, log=False),
                    dir_config.get('context', {}),
                    system.file_templates,
                )
                for dir_config in json['roms']['dirs']
            ]

        # Attributes
        if 'attributes' in json:
            for attribute_name, attribute_config in json['attributes'].items():
                system.reconfigure_attribute(attribute_name, attribute_config)

        return system

    # Sorts the prioritized machines list by name
    @property
    def sorted_prioritized_machines(self) -> List[Machine]:
        return sorted(self.prioritized_machines, key=lambda machine: machine.name)

    # Finds the machine attribute with the given name
    def attribute(self, name: str) -> BaseAttribute:
        return next(filter(lambda attr: attr.metadata_name == name or attr.rule_name == name, self.attributes), None)

    # Configures an attribute with the given overrides
    def reconfigure_attribute(self, name: str, config: Dict[str, Any] = {}) -> None:
        defaults = {
            'install_paths': [system_dir.path for system_dir in self.dirs],
        }

        self.attribute(name).configure(**defaults, **config)

    # Sorts the machines available in each romset
    def load(self, force: bool = False) -> bool:
        if self._loaded and not force:
            return False

        self.machines.clear()
        self.prioritized_machines.clear()

        # Filter and sort
        for romset in self.romsets:
            romset.load()

            for machine, allow_reason in self._filter_romset(romset).items():
                if allow_reason == RuleMatchReason.OVERRIDE:
                    self.machines.override(machine)
                else:
                    self.machines.add(machine)

        # Cache prioritized list
        self.prioritized_machines = self.machines.prioritize()

        # Update favorites / collections
        for machine in self.prioritized_machines:
            machine.favorite = self.favorites_rules.match(machine) is not None
            machine.collections.update(self.collections.list(machine))

        self._loaded = True
        return True

    # Filters the machines in the given romset
    def _filter_romset(self, romset: ROMSet) -> Dict[Machine, RuleMatchReason]:
        return romset.filter_machines(self.filters, self.metadata)

    # Generates the list of machines to target, based are predefined priorities
    def list(self) -> List[Machine]:
        self.load()
        return self.sorted_prioritized_machines

    # Installs all of the filtered machines
    def install(self) -> None:
        # Install and filter out invalid machines
        machines = self.list()
        for machine in machines:
            machine.before_install()

        for machine in machines:
            self.install_machine(machine)

        self.organize()

    # Installs the given machine and returns true/false depending on whether the
    # install was successful
    def install_machine(self, machine: Machine) -> bool:
        for attempt in range(INSTALL_MAX_ATTEMPTS):
            try:
                machine.install()
                return True
            except (requests.exceptions.MissingSchema, requests.exceptions.URLRequired) as e:
                logging.error(f'[{machine.name}] Failed to download (no url found)')
                break
            except Exception as e:
                logging.error(f'[{machine.name}] Install failed')
                traceback.print_exc()
                time.sleep(INSTALL_RETRY_WAIT_TIME)

        return False

    # Organizes the directory structure based on the current list of valid
    # installed machines
    def organize(self) -> None:
        self.load()
        self.reset_directories()

        for machine in self.sorted_prioritized_machines:
            if not self.stub and not machine.is_valid_nonmerged():
                logging.warn(f'[{machine.name}] is not a valid non-merged ROM')
                continue

            # Enable machine in directories that are filtering for it
            machine.clean()
            for system_dir in self.dirs:
                if system_dir.allow(machine):
                    self.enable_machine(machine, system_dir)

    # Reset the visible set of machines
    def reset_directories(self) -> None:
        for system_dir in self.dirs:
            system_dir.reset()

    # Enables the given machine in the given directory
    def enable_machine(self, machine: Machine, system_dir: SystemDir) -> None:
         machine.enable(system_dir)

    # Purges machines that were not installed
    def vacuum(self) -> None:
        # Identify all of the valid paths for machines that are installed
        installable_paths = set()
        for machine in self.list():
            resource_models = list(filter(None, {machine, machine.sample, machine.playlist} | machine.disks))

            for resource_model in resource_models:
                resource = resource_model.resource
                if resource:
                    installable_paths.add(resource.target_path.path)
                    if resource.is_locally_sourced:
                        installable_paths.add(resource.source_url_path)
                    if resource.xref_path:
                        installable_paths.add(resource.xref_path.path)

        # Ensure we're accounting for static resources from the templates themselves
        for romset in self.romsets:
            for resource_template in romset.resource_templates.values():
                if resource_template.is_locally_sourced:
                    installable_paths.add(resource_template.source_url_path)

        # Identify the installable path globs.  It's important that the context
        # includes all of the necessary glob patterns, otherwise this'll error out.
        installable_path_globs = set()
        resource_names = {'machine', 'disk', 'sample', 'playlist'}
        resource_context = {
            'disk': '*',
            'machine': '*',
            'machine_description': '*',
            'machine_id': '*',
            'machine_sourcefile': '*',
            'parent': '*',
            'playlist': '*',
            'rom_root': '*',
            'sample': '*',
            'sha1': '*',
            'url': '',
        }
        for romset in self.romsets:
            for resource_name in resource_names:
                resource = romset.resource(resource_name, **resource_context)
                if resource:
                    resource_paths = map(
                        lambda resource_path: resource_path.path,
                        filter(None, [
                            resource.download_path,
                            resource.target_path,
                            resource.xref_path,
                        ])
                    )

                    installable_path_globs.update(resource_paths)

        # Look up all files that match the path template glob pattern.  If they
        # weren't tracked as an installable resource, then we know they can be
        # deleted.
        # 
        # Paths are sorted to make for prettier output.
        for path_glob in sorted(installable_path_globs):
            for path in sorted(Path('/').glob(str(path_glob)[1:])):
                if path not in installable_paths:
                    print(f'rm -rfv {shlex.quote(str(path))}')
