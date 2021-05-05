from __future__ import annotations

from romkit.util import Downloader

import csv
import re
import tempfile
import unicodedata
from pathlib import Path
from typing import Dict, Optional
from urllib.parse import urlparse

# Compatibility layer for ensuring the appropriate emulator is used
class EmulatorSet():
    ASCII_REGEX = re.compile(r'[^a-z0-9]+')

    def __init__(self,
        system: BaseSystem,
        url: str = None,
        column_rom: int = 0,
        column_emulator: int = 1,
        key: str = 'name',
        overrides: Dict[str, str] = {},
        delimiter: str = '\t',
        filter = False,
    ) -> None:
        self.system = system
        self.url = url
        self.column_rom = column_rom
        self.column_emulator = column_emulator
        self.key = key
        self.delimiter = delimiter
        self.emulators = overrides
        self.filter = filter

        if self.url:
            self.download()
            self.load()

    @classmethod
    def from_json(self, system: BaseSystem, json: dict) -> EmulatorSet:
        return self(system, **json)

    def download(self) -> None:
        if urlparse(self.url).scheme == 'file':
            # Use locally sourced path
            self.path = Path(urlparse(self.url).path)
        else:
            # Download remote path
            tmp_dir = Path(f'{tempfile.gettempdir()}/{self.system.name}')
            tmp_dir.mkdir(parents=True, exist_ok=True)

            self.path = tmp_dir.joinpath('emulators.tsv')
            if not self.path.exists():
                Downloader.instance().get(self.url, self.path)

    def load(self) -> None:
        with self.path.open() as file:
            rows = csv.reader(file, delimiter=self.delimiter)
            for row in rows:
                if len(row) <= self.column_rom or len(row) <= self.column_emulator:
                    continue

                rom_key = row[self.column_rom]
                emulator = row[self.column_emulator]

                if rom_key not in self.emulators and emulator and emulator != '':
                    self.emulators[rom_key] = emulator

    def get(self, machine: Machine) -> Optional[str]:
        machine_key = getattr(machine, self.key)
        parent_key = getattr(machine, f'parent_{self.key}')

        return self.emulators.get(machine_key) or self.emulators.get(parent_key)
