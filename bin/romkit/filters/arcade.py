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
TMP_DIR = Path(f'{tempfile.gettempdir()}/arcade')
TMP_DIR.mkdir(parents=True, exist_ok=True)

# Looks for the pattern in the content of the given url
def scrape(url: str, pattern: str) -> str:
    result = None

    with tempfile.TemporaryDirectory() as tmpdir:
        download_path = Path(tmpdir).joinpath('output.html')
        Downloader.instance().get(url, download_path)

        with download_path.open('r') as file:
            for line in file:
                match = re.search(pattern, line)
                if match:
                    result = match.group(1)
                    break
    
    return result             


# Downloads from the given url and extracts a specific archive to the target
def download_and_extract(url: str, download_path: Path, archive_name: str, target_path: Path) -> None:
    Downloader.instance().get(url, download_path)

    with zipfile.ZipFile(download_path, 'r') as zip_ref:
        zip_info = zip_ref.getinfo(archive_name)
        zip_info.filename = target_path.name
        zip_ref.extract(zip_info, target_path.parent)


# Reads the INI configuration at the given path
def read_config(path: Path) -> configparser.ConfigParser:
    with path.open('r') as file:
        config = configparser.ConfigParser(allow_no_value=True)
        contents = file.read()
        config.read_string(contents.encode('ascii', 'ignore').decode())
        return config

# Filter on the language used in the machine
class LanguageFilter(ExactFilter):
    name = 'languages'

    URL = 'https://www.progettosnaps.net/download/?tipo=languages&file=pS_Languages_{version}.zip'
    SCRAPE_URL = 'https://www.progettosnaps.net/languages/'
    VERSION_PATTERN = r'pS_Languages_([0-9]+).zip'
    ARCHIVE_FILE = 'folders/languages.ini'

    def download(self) -> None:
        self.config_path = Path(f'{TMP_DIR}/languages.ini')

        if not self.config_path.exists():
            version = scrape(self.SCRAPE_URL, self.VERSION_PATTERN)

            download_and_extract(
                self.URL.format(version=version),
                Path(f'{TMP_DIR}/languages.zip'),
                self.ARCHIVE_FILE,
                self.config_path,
            )

    def load(self) -> None:
        self.languages = {}

        config = read_config(self.config_path)
        for section in config.sections():
            for name, value in config.items(section, raw=True):
                self.languages[name] = section

    def values(self, machine):
        return {self.languages.get(machine.name)}


# Filter on how the machine is categorized
class CategoryFilter(SubstringFilter):
    name = 'categories'

    URL = 'https://www.progettosnaps.net/download/?tipo=catver&file=pS_CatVer_{version}.zip'
    SCRAPE_URL = 'https://www.progettosnaps.net/catver/'
    VERSION_PATTERN = r'pS_CatVer_([0-9]+).zip'
    ARCHIVE_FILE = 'UI_files/catlist.ini'

    def download(self) -> None:
        self.config_path = Path(f'{TMP_DIR}/categories.ini')

        if not self.config_path.exists():
            version = scrape(self.SCRAPE_URL, self.VERSION_PATTERN)

            download_and_extract(
                self.URL.format(version=version),
                Path(f'{TMP_DIR}/categories.zip'),
                self.ARCHIVE_FILE,
                self.config_path,
            )

    def load(self):
        self.categories = {}

        config = read_config(self.config_path)
        for section in config.sections():
            for name, value in config.items(section, raw=True):
                self.categories[name] = section

    def values(self, machine):
        return {self.categories.get(machine.name)}


# Filter on a subjective rating for the machine
class RatingFilter(ExactFilter):
    name = 'ratings'

    URL = 'https://www.progettosnaps.net/download/?tipo=bestgames&file=pS_BestGames_{version}.zip'
    SCRAPE_URL = 'https://www.progettosnaps.net/bestgames/'
    VERSION_PATTERN = r'pS_BestGames_([0-9]+).zip'
    ARCHIVE_FILE = 'folders/bestgames.ini'

    def download(self) -> None:
        self.config_path = Path(f'{TMP_DIR}/ratings.ini')

        if not self.config_path.exists():
            version = scrape(self.SCRAPE_URL, self.VERSION_PATTERN)

            download_and_extract(
                self.URL.format(version=version),
                Path(f'{TMP_DIR}/ratings.zip'),
                self.ARCHIVE_FILE,
                self.config_path,
            )

    def load(self):
        self.ratings = {}

        config = read_config(self.config_path)
        for section in config.sections():
            for name, value in config.items(section, raw=True):
                self.ratings[name] = section

    def values(self, machine):
        return {self.ratings.get(machine.name)}


# Filter on the emulator known to be compatible with the machine
class EmulatorFilter(ExactFilter):
    apply_to_favorites = True
    
    # Roslof compatibility list
    URL = 'https://docs.google.com/spreadsheets/d/1Rq4shU1RUSdcc7cTVWeORMD-mcO6BwXwQ7TGw8f5_zw/export?gid=0&format=tsv'

    # TSV Columns
    COLUMN_ROM = 0
    COLUMN_EMULATOR = 2
    COLUMN_FPS = 5
    COLUMN_VISUALS = 6
    COLUMN_AUDIO = 7
    COLUMN_CONTROLS = 8
    QUALITY_COLUMNS = [COLUMN_FPS, COLUMN_VISUALS, COLUMN_AUDIO, COLUMN_CONTROLS]

    def download(self) -> None:
        self.config_path = Path(f'{TMP_DIR}/emulators.tsv')
        if not self.config_path.exists():
            Downloader.instance().get(self.URL, self.config_path)

    def load(self):
        self.emulators = {}

        with open(self.config_path) as file:
            rows = csv.read(file, delimiter='\t')
            for row in rows:
                if not any(row[col] == 'x' or row[col] == '!' for col in self.QUALITY_COLUMNS):
                    self.emulators[row[self.COLUMN_ROM]] = row[self.COLUMN_EMULATOR]

        # Use overrides when necessary
        overrides = self.config['roms'].get('emulator_overrides')
        if overrides:
            for machine_name, emulator in overrides.items():
                self.emulators[machine_name] = emulator

    def allow(self, machine):
        emulator = self.emulators.get(machine.name)
        allowed = emulator == machine.emulator

        if not allowed and self.log:
            logging.info(f'[{machine.name}] Skip ({type(self).__name__})')

        return allowed
