from __future__ import annotations

import logging
import shlex

# Represents an audio file used by a machine
class Sample:
    def __init__(self, machine: Machine, name: str) -> None:
        self.machine = machine
        self.name = name

    @property
    def romset(self) -> ROMSet:
        return self.machine.romset

    # Builds context for formatting dirs/urls
    @property
    def context(self) -> dict:
        context = {
            'sample': self.name,
            **self.machine.context,
        }
        context['sample_filename'] = self.romset.resource('sample', **context).target_path.path.name
        return context

    # Target destination for installing this sample
    @property
    def resource(self) -> Resource:
        return self.romset.resource('sample', **self.context)

    # Downloads and installs the sample
    def install(self) -> None:
        logging.info(f'[{self.machine.name}] Installing sample {self.name}')
        self.resource.install()

    # Removes this sample from the filesystem
    def purge(self):
        if self.resource.target_path.exists():
            print(f'rm -rf {shlex.quote(self.resource.target_path.path)}')
