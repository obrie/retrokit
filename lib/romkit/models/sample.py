from __future__ import annotations

import logging

# Represents an audio file used by a machine
class Sample:
    def __init__(self, machine: Machine, name: str) -> None:
        self.machine = machine
        self.name = name
        self._resource = None

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Builds context for formatting dirs/urls, including resource filenames
    @property
    def context(self) -> dict:
        return {
            **self._resource_context,
            'sample_filename': self.resource.target_path.path.name,
        }

    # Builds context for formatting dirs/urls
    @property
    def _resource_context(self) -> dict:
        return {
            'sample': self.name,
            **self.machine.context,
        }

    # Target destination for installing this sample
    @property
    def resource(self) -> Resource:
        if not self._resource:
            self._resource = self.romset.resource('sample', **self._resource_context)
        return self._resource

    # Downloads and installs the sample
    def install(self) -> None:
        logging.info(f'[{self.machine.name}] Installing sample {self.name}')
        self.resource.check_xref()
        self.resource.install()
        self.resource.create_xref()
