from romkit.filters.base import ExactFilter, SubstringFilter
from romkit.util import Downloader

import configparser
import csv
import io
import logging
import re
import zipfile
import tempfile
from pathlib import Path

# Arcade-specific temp dir
TMP_DIR = Path(f'{tempfile.gettempdir()}/n64')
TMP_DIR.mkdir(parents=True, exist_ok=True)

# Filter on the emulator known to be compatible with the machine
class EmulatorFilter(ExactFilter):
    apply_to_favorites = True
    
    # Roslof compatibility list
    URL = 'https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/export?gid=1983504515&format=tsv'

    # TSV Columns
    COLUMN_ROM = 0
    COLUMN_EMULATOR = 1

    EMULATOR_REGEX = re.compile(r'^(lr-mupen64plus|mupen64plus)')

    def download(self) -> None:
        self.config_path = Path(f'{TMP_DIR}/emulators.tsv')
        if not self.config_path.exists():
            Downloader.instance().get(self.URL, self.config_path)

    def load(self):
        self.emulators = {}

        with open(self.config_path) as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                match = self.EMULATOR_REGEX.search(row[self.COLUMN_EMULATOR])
                if match:
                    emulator = match.group().strip()
                    print(emulator)
                    print(row[self.COLUMN_ROM])
                    self.emulators[row[self.COLUMN_ROM]] = emulator

        # Use overrides when necessary
        overrides = self.config['roms'].get('emulator_overrides')
        if overrides:
            for machine_name, emulator in overrides.items():
                self.emulators[machine_name] = emulator

    def allow(self, machine):
        emulator = self.emulators.get(machine.title)
        if not machine.emulator:
            machine.emulator = emulator

        allowed = emulator and (emulator == machine.emulator)

        if not allowed and self.log:
            logging.info(f'[{machine.name}] Skip ({type(self).__name__})')

        return allowed
