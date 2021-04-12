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

def scrape(url, pattern):
    result = None

    with tempfile.TemporaryDirectory() as tmpdir:
        filepath = Path(tmpdir).joinpath('output.html')
        Downloader.instance().get(url, filepath)

        file = open(filepath, 'r')
        for line in file:
            match = re.search(pattern, line)
            if match:
                result = match.group(1)
                break
    
    return result             


def download_and_extract(url, download_file, archive_file, target_file):
    Downloader.instance().get(url, download_file)
    with zipfile.ZipFile(download_file, 'r') as zip_ref:
        zip_info = zip_ref.getinfo(archive_file)
        zip_info.filename = Path(target_file).stem
        zip_ref.extract(zip_info, Path(target_file).parent)


def read_config(filepath):
    with open(filepath, 'r') as file:
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

    def download(self):
        target_file = f'{tempfile.gettempdir()}/languages.ini'

        if not Path(target_file).exists():
            version = scrape(LanguageFilter.SCRAPE_URL, LanguageFilter.VERSION_PATTERN)

            download_and_extract(
                LanguageFilter.URL.format(version=version),
                f'{tempfile.gettempdir()}/languages.zip',
                LanguageFilter.ARCHIVE_FILE,
                target_file,
            )

    def load(self):
        self.languages = {}

        config = read_config(f'{tempfile.gettempdir()}/languages.ini')
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

    def download(self):
        target_file = f'{tempfile.gettempdir()}/categories.ini'

        if not Path(target_file).exists():
            version = scrape(CategoryFilter.SCRAPE_URL, CategoryFilter.VERSION_PATTERN)

            download_and_extract(
                CategoryFilter.URL.format(version=version),
                f'{tempfile.gettempdir()}/categories.zip',
                CategoryFilter.ARCHIVE_FILE,
                target_file,
            )

    def load(self):
        self.categories = {}

        config = read_config(f'{tempfile.gettempdir()}/categories.ini')
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

    def download(self):
        target_file = f'{tempfile.gettempdir()}/ratings.ini'

        if not Path(target_file).exists():
            version = scrape(RatingFilter.SCRAPE_URL, RatingFilter.VERSION_PATTERN)

            download_and_extract(
                RatingFilter.URL.format(version=version),
                f'{tempfile.gettempdir()}/ratings.zip',
                RatingFilter.ARCHIVE_FILE,
                target_file,
            )

    def load(self):
        self.ratings = {}

        config = read_config(f'{tempfile.gettempdir()}/ratings.ini')
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
    COLUMN_ROM = 'Rom'
    COLUMN_EMULATOR = 'Recommended Emulator'
    COLUMN_FPS = 'FPS'
    COLUMN_VISUALS = 'Visuals'
    COLUMN_AUDIO = 'Audio'
    COLUMN_CONTROLS = 'Controls'
    QUALITY_COLUMNS = [COLUMN_FPS, COLUMN_VISUALS, COLUMN_AUDIO, COLUMN_CONTROLS]

    def download(self):
        filepath = f'{tempfile.gettempdir()}/emulators.tsv'
        if not Path(filepath).exists():
            Downloader.instance().get(EmulatorFilter.URL, filepath)

    def load(self):
        self.emulators = {}

        filepath = f'{tempfile.gettempdir()}/emulators.tsv'
        with open(filepath) as file:
            rows = csv.DictReader(file, delimiter='\t')
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
        allowed = emulator == machine.romset.emulator

        if not allowed and self.log:
            logging.info(f'[{machine.name}] Skip ({type(self).__name__})')

        return allowed
