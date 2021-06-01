from __future__ import annotations

from romkit.filters.base import ExactFilter
from romkit.util import Downloader

import csv
import tempfile
from typing import Optional, Set
from pathlib import Path
from urllib.parse import urlparse

# Arcade-specific temp dir
TMP_DIR = Path(f'{tempfile.gettempdir()}/saturn')
TMP_DIR.mkdir(parents=True, exist_ok=True)


# Filter on the compatibility rating of the game
class CompatibilityRatingFilter(ExactFilter):
    name = 'compatibility_ratings'

    def download(self) -> None:
        url = self.config['roms']['compatibility_rating_url']

        if urlparse(url).scheme == 'file':
            # Use locally sourced path
            self.config_path = Path(urlparse(url).path)
        else:
            self.config_path = Path(f'{TMP_DIR}/compatility_ratings.tsv')
            if not self.config_path.exists():
                Downloader.instance().get(url, self.config_path)

    def load(self):
        self.compatibility_ratings = {}

        with self.config_path.open() as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                rom = row[0]
                rating = row[1]
                self.compatibility_ratings[rom] = int(rating)

    def normalize(self, values: Set) -> Set[Optional[int]]:
        # Avoid normalization
        return values

    def values(self, machine: Machine) -> Set[Optional[int]]:
        return {self.compatibility_ratings.get(machine.title)}
