from __future__ import annotations

from romkit.filters.base import SubstringFilter
from romkit.util import Downloader

import csv
import re
import tempfile
from pathlib import Path

# Arcade-specific temp dir
TMP_DIR = Path(f'{tempfile.gettempdir()}/c64')
TMP_DIR.mkdir(parents=True, exist_ok=True)


# Filter on the emulator known to be compatible with the machine
class C64DreamsFilter(SubstringFilter):
    name = 'c64_dreams'

    # C64 Dreams list
    URL = 'https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4/export?gid=82569470&format=csv'

    # TSV Columns
    COLUMN_TITLE = 2
    COLUMN_TYPE = 3

    # Characters to match in order to account for differences in case and characters
    # like hyphen, apostrophe, etc.
    TITLE_CLEAN_REGEX = re.compile(r'[^a-z0-9]')
    TITLE_MATCH_REGEX = re.compile(r'^[^\(]+')

    # List of archive types to verify that the row we're iterating over is a valid
    # game in the spreadsheet
    VALID_TYPES = {'crt', 'd64', 'd81', 'EF', 'g64', 't64'}

    def download(self) -> None:
        self.config_path = Path(f'{TMP_DIR}/dreams.csv')
        if not self.config_path.exists():
            Downloader.instance().get(self.URL, self.config_path)

    def load(self):
        # Ignore the list of values coming from the config
        self.filter_values = set()

        with open(self.config_path) as file:
            rows = csv.reader(file)
            for row in rows:
                # There are some extraneous rows, so we double check that there's enough
                # data in the row as a safety check before attempting to parse
                if len(row) > self.COLUMN_TYPE:
                    archive_type = row[self.COLUMN_TYPE]
                    if archive_type in self.VALID_TYPES:
                        # Only select characters up to the parens
                        title = self.TITLE_MATCH_REGEX.search(row[self.COLUMN_TITLE]).group().strip()
                        self.filter_values.add(self._clean_title(title))

    def values(self, machine: Machine) -> set:
        return {self._clean_title(machine.title)}

    # Builds a title that is consistent between the DAT and the C64 Dreams spreadsheet
    def _clean_title(self, title: str) -> str:
        return self.TITLE_CLEAN_REGEX.sub('', title.lower())
