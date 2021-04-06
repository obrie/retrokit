from romkit.filters.base import ExactFilter, SubstringFilter
from romkit.util import Downloader

import configparser
import csv
import io
import logging
import os
import zipfile
import tempfile
from pathlib import Path

def download_and_extract(url, download_file, archive_file, target_file):
    if not Path(target_file).exists():
        Downloader.instance().get(url, download_file)
        with zipfile.ZipFile(download_file, 'r') as zip_ref:
            zip_info = zip_ref.getinfo(archive_file)
            zip_info.filename = os.path.basename(target_file)
            zip_ref.extract(zip_info, os.path.dirname(target_file))


def read_config(filepath):
    with open(filepath, 'r') as file:
        config = configparser.ConfigParser(allow_no_value=True)
        contents = file.read()
        config.read_string(contents.encode('ascii', 'ignore').decode())
        return config

# Filter on the language used in the machine
class LanguageFilter(ExactFilter):
    name = 'languages'

    URL = 'https://www.progettosnaps.net/download/?tipo=languages&file=pS_Languages_230.zip'
    ARCHIVE_FILE = 'folders/languages.ini'

    def download(self):
        download_and_extract(
            LanguageFilter.URL,
            f'{tempfile.gettempdir()}/languages.zip',
            LanguageFilter.ARCHIVE_FILE,
            f'{tempfile.gettempdir()}/languages.ini',
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

    URL = 'https://www.progettosnaps.net/download/?tipo=catver&file=pS_CatVer_230.zip'
    ARCHIVE_FILE = 'UI_files/catlist.ini'

    def download(self):
        download_and_extract(
            CategoryFilter.URL,
            f'{tempfile.gettempdir()}/categories.zip',
            CategoryFilter.ARCHIVE_FILE,
            f'{tempfile.gettempdir()}/categories.ini',
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

    URL = 'https://www.progettosnaps.net/download/?tipo=bestgames&file=pS_BestGames_229.zip'
    ARCHIVE_FILE = 'folders/bestgames.ini'

    def download(self):
        download_and_extract(
            RatingFilter.URL,
            f'{tempfile.gettempdir()}/ratings.zip',
            RatingFilter.ARCHIVE_FILE,
            f'{tempfile.gettempdir()}/ratings.ini',
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
