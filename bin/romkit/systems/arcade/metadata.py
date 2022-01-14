from __future__ import annotations

from romkit.metadata.external import ExternalMetadata
from romkit.metadata import EmulatorMetadata

import configparser
import csv
import re
import tempfile
from pathlib import Path

class ProgrettoSnapsMetadata(ExternalMetadata):
    SCRAPE_URL = None
    VERSION_PATTERN = None
    default_context = {'version': ''}

    @property
    def context(self) -> dict:
        return {'version': self._find_latest_version()}

    # Looks for the pattern in the content of the given url
    def _find_latest_version(self) -> str:
        result = None

        with tempfile.TemporaryDirectory() as tmpdir:
            download_path = Path(tmpdir).joinpath('output.html')
            self.downloader.get(self.SCRAPE_URL, download_path)

            with download_path.open('r') as file:
                for line in file:
                    match = re.search(self.VERSION_PATTERN, line)
                    if match:
                        result = match.group(1)
                        break

        return result

    # Loads the data from the INI configuration.
    # 
    # Format:
    # * Section: value for the metadata
    # * Key: name of the machine
    def load(self) -> None:
        self.values = {}

        with self.install_path.open('r') as file:
            config = configparser.ConfigParser(allow_no_value=True)
            config.read_string(file.read().encode('ascii', 'ignore').decode())

            for section in config.sections():
                for name, value in config.items(section, raw=True):
                    self.values[name] = section


# Language metadata managed by progretto-SNAPS
# 
# Format: INI
class LanguageMetadata(ProgrettoSnapsMetadata):
    name = 'language'

    SCRAPE_URL = 'https://www.progettosnaps.net/languages/'
    VERSION_PATTERN = r'pS_Languages_([0-9]+).zip'

    def update(self, machine: Machine) -> None:
        language = self.values.get(machine.name)
        if language:
            machine.languages.add(language)


# Genre metadata managed by progretto-SNAPS
# 
# Format: INI
class GenreMetadata(ProgrettoSnapsMetadata):
    name = 'genre'

    SCRAPE_URL = 'https://www.progettosnaps.net/catver/'
    VERSION_PATTERN = r'pS_CatVer_([0-9]+).zip'

    def update(self, machine: Machine) -> None:
        genre = self.values.get(machine.name)
        if genre:
            machine.genres.add(genre)


# User rating metadata managed by progretto-SNAPS
# 
# Format: INI
class RatingMetadata(ProgrettoSnapsMetadata):
    name = 'rating'

    SCRAPE_URL = 'https://www.progettosnaps.net/bestgames/'
    VERSION_PATTERN = r'pS_BestGames_([0-9]+).zip'

    def update(self, machine: Machine) -> None:
        machine.rating = self.values.get(machine.name)


# Compatibility layer for ensuring the appropriate emulator is used
# 
# Format: TSV (default)
#  
# Columns:
# * 0 - ROM Name
# * 2 - Emulator Name
# * 5 - FPS quality
# * 6 - Visual quality
# * 7 - Audio quality
# * 8 - Controls quality
class ArcadeEmulatorMetadata(EmulatorMetadata):
    name = 'emulator'

    # TSV Columns
    COLUMN_ROM = 0
    COLUMN_EMULATOR = 2
    COLUMN_FPS = 3
    COLUMN_VISUALS = 4
    COLUMN_AUDIO = 5
    COLUMN_CONTROLS = 6
    QUALITY_COLUMNS = [COLUMN_FPS, COLUMN_VISUALS, COLUMN_AUDIO, COLUMN_CONTROLS]

    def read_row(self, row: List[str]) -> dict:
        if len(row) <= self.COLUMN_CONTROLS:
            # Not a valid row in the compatibility list
            return

        name = row[self.COLUMN_ROM]
        emulator = row[self.COLUMN_EMULATOR]

        rating = 5
        for col in self.QUALITY_COLUMNS:
            if row[col] == 'x' or row[col] == '!':
                rating -= 1

        return {'rom': name, 'emulator': emulator, 'rating': rating}
