from __future__ import annotations

from romkit.models.machine import Machine
from romkit.resources.resource import ResourceTemplate
from romkit.util import Downloader

# Provides a base class for loading attributes external to a romset's DAT
class ExternalMetadata:
    name = None
    default_context = {}

    def __init__(self,
        config: dict = {},
        downloader: Downloader = Downloader.instance(),
    ) -> None:
        self.config = config
        self.downloader = downloader
        self.data = {}

        if 'source' in config:
            # If this has an external source attached to it, let's try to
            # install it
            self.resource_template = ResourceTemplate.from_json(
                config,
                downloader=downloader,
            )
            self.install()
        else:
            self.resource_template = None

        self.load()

    # Target destination for installing this attribute data
    @property
    def resource(self) -> Resource:
        if self.resource_template:
            # Avoid building context if we can since it may result in downloading
            # unnecessary external data
            resource = self.resource_template.render(**self.default_context)
            if resource.target_path.exists():
                return resource
            else:
                return self.resource_template.render(**self.context)

    # Path that the external data has been installed
    @property
    def install_path(self) -> Path:
        resource = self.resource
        if resource:
            return resource.target_path.path

    # Builds context for formatting urls
    @property
    def context(self) -> dict:
        return {}

    # Installs the externally-sourced data
    def install(self) -> None:
        self.resource.install()

    # Associates the key with the given data.
    # 
    # This will also associate the normalized key in case there are any differences
    # between the data we have and what's in the romset.
    def set_data(self, key: str, key_data) -> None:
        self.data[key] = key_data
        self.data[Machine.normalize(key)] = key_data

    # Looks up the data associated with the given machine.  This will attempt to find
    # based on priority of `find_matching_key`.
    def get_data(self, machine: Machine):
        key = self.find_matching_key(machine, self.data.keys())
        if key:
            return self.data[key]

    # Determines whether the machine is in the list of keys.  The following machine
    # attributes will be used to find a matching key (in order of priority):
    # 
    # * Name
    # * Normalized name
    # * Title
    # * Normalized title
    # * Parent name
    # * Normalized Parent name
    # * Parent title
    # * Normalized Parent title
    # 
    # The first match will be returned
    def find_matching_key(self, machine: Machine, all_keys: Set[str]):
        keys = [machine.name, machine.title, machine.parent_name, machine.parent_title]
        for key in keys:
            if not key:
                continue

            if key in all_keys:
                return key
            else:
                normalized_key = Machine.normalize(key)
                if normalized_key in all_keys:
                    return normalized_key

    # Loads all of the relevant data needed to machine attributes
    def load(self) -> None:
        pass

    def update(self, machine: Machine) -> None:
        pass
