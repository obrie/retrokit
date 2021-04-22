from __future__ import annotations

from romkit.util import Downloader

import csv
import tempfile
from pathlib import Path
from typing import Dict, Optional

# Compatibility layer for ensuring the appropriate emulator is used
class EmulatorSet():
    def __init__(self,
        system: BaseSystem,
        url: str = None,
        column_rom: int = 0,
        column_emulator: int = 1,
        key = 'name',
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
        tmp_dir = Path(f'{tempfile.gettempdir()}/{self.system.name}')
        tmp_dir.mkdir(parents=True, exist_ok=True)

        self.path = tmp_dir.joinpath('emulators.tsv')
        if not self.path.exists():
            Downloader.instance().get(self.url, self.path)

    def load(self) -> None:
        with self.path.open() as file:
            rows = csv.reader(file, delimiter=self.delimiter)
            for row in rows:
                rom = row[self.column_rom]
                emulator = row[self.column_emulator]

                if rom not in self.emulators:
                    self.emulators[rom] = emulator

    def get(self, machine: Machine) -> Optional[str]:
        return self.emulators.get(getattr(machine, self.key))
