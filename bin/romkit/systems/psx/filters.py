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

# Arcade-specific temp dir
TMP_DIR = Path(f'{tempfile.gettempdir()}/psx')
TMP_DIR.mkdir(parents=True, exist_ok=True)


# Downloads from the given url and extracts a specific archive to the target
def download_and_extract(url: str, download_path: Path, archive_name: str, target_path: Path) -> None:
    Downloader.instance().get(url, download_path)

    with zipfile.ZipFile(download_path, 'r') as zip_ref:
        zip_info = zip_ref.getinfo(archive_name)
        zip_info.filename = target_path.name
        zip_ref.extract(zip_info, target_path.parent)


URL = 'https://github.com/stenzek/duckstation/releases/download/latest/duckstation-windows-arm64-release.zip'
ARCHIVE_FILE = 'database/gamedb.json'
GAMEDB_PATH = Path(f'{TMP_DIR}/categories.json')

def download_gamedb() -> None:
    if not GAMEDB_PATH.exists():
        download_and_extract(URL, TMP_DIR.joinpath('duckstation.zip'), ARCHIVE_FILE, GAMEDB_PATH)

# Filter on how the game is categorized
class CategoryFilter(SubstringFilter):
    name = 'categories'

    def download(self) -> None:
        download_gamedb()

    def load(self):
        self.categories = {}

        with GAMEDB_PATH.open() as file:
            data = json.load(file)
            for game in data:
                if 'genre' in game:
                    self.categories[game['name']] = game['genre'].lower()

    def values(self, machine):
        return {self.categories.get(machine.name)}

# Filter on the language used in the game
class LanguageFilter(SubstringFilter):
    name = 'languages'

    def download(self) -> None:
        download_gamedb()

    def load(self):
        self.languages = {}

        with GAMEDB_PATH.open() as file:
            data = json.load(file)
            for game in data:
                if 'languages' in game:
                    self.languages[game['name']] = ' '.join(game['languages']).lower()

    def values(self, machine):
        return {self.languages.get(machine.name)}
