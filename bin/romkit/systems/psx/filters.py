from romkit.filters.base import ExactFilter, SubstringFilter
from romkit.util import Downloader

import configparser
import csv
import io
import json
import logging
import re
import zipfile
import tempfile
from pathlib import Path

# PSX-specific temp dir
TMP_DIR = Path(f'{tempfile.gettempdir()}/psx')
TMP_DIR.mkdir(parents=True, exist_ok=True)

URL = 'https://github.com/stenzek/duckstation/raw/master/data/database/gamedb.json'
GAMEDB_PATH = Path(f'{TMP_DIR}/gamedb.json')

# Filter on how the game is categorized
class CategoryFilter(SubstringFilter):
    name = 'categories'

    def download(self) -> None:
        Downloader.instance().get(URL, GAMEDB_PATH)

    def load(self):
        self.categories = {}

        with GAMEDB_PATH.open() as file:
            data = json.load(file)
            for game in data:
                if 'genre' in game:
                    self.categories[game['name']] = game['genre'].lower()

    def values(self, machine):
        return {self.categories.get(machine.name) or self.categories.get(machine.parent_name)}

# Filter on the language used in the game
class LanguageFilter(SubstringFilter):
    name = 'languages'

    def download(self) -> None:
        Downloader.instance().get(URL, GAMEDB_PATH)

    def load(self):
        self.languages = {}

        with GAMEDB_PATH.open() as file:
            data = json.load(file)
            for game in data:
                if 'languages' in game:
                    self.languages[game['name']] = ' '.join(game['languages']).lower()

    def values(self, machine):
        return {self.languages.get(machine.name) or self.languages.get(machine.parent_name)}
