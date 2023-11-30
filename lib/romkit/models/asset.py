from __future__ import annotations

import logging
from pathlib import Path

# Represents an external asset used by a machine
class Asset:
    def __init__(self, machine: Machine, name: str) -> None:
        self.machine = machine
        self.name = name

        self._resource = None

    # Builds context for formatting dirs/urls, including resource filenames
    @property
    def context(self) -> dict:
        return {
            **self._resource_context,
            'asset_filename': self.resource.target_path.path.name,
        }

    # Builds context for formatting dirs/urls
    @property
    def _resource_context(self) -> dict:
        return self.machine.context

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Target destination for installing this asset
    @property
    def resource(self) -> Resource:
        if not self._resource:
            self._resource = self.romset.resource(self.name, **self._resource_context)
        return self._resource

    # Downloads and installs the asset
    def install(self) -> None:
        logging.info(f'[{self.machine.name}] Installing asset "{self.name}"')
        self.resource.install()

    # Enables the asset to be accessible to the machine
    def enable(self, system_dir: SystemDir) -> None:
        system_dir.symlink(self.name, self.resource, **self.context)

    # Equality based on Unique Name
    def __eq__(self, other) -> bool:
        if isinstance(other, Asset):
            return self.name == other.name
        return False

    # Hash based on Unique Name
    def __hash__(self) -> str:
        return hash(self.name)
