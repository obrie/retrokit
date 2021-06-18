from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv
import re
from pathlib import Path

# C64 Dreams collection
# 
# Format: CSV
# 
# Columns:
# * 2 - ROM Title
# * 3 - Archive Type
class C64DreamsMetadata(ExternalMetadata):
    name = 'c64_dreams'

    # CSV Columns
    COLUMN_TITLE = 2
    COLUMN_TYPE = 3

    # Characters to match in order to account for differences in case and characters
    # like hyphen, apostrophe, etc.
    TITLE_CLEAN_REGEX = re.compile(r'[^a-z0-9]')
    TITLE_MATCH_REGEX = re.compile(r'^[^\(]+')

    # List of archive types to verify that the row we're iterating over is a valid
    # game in the spreadsheet
    VALID_TYPES = {'crt', 'd64', 'd81', 'EF', 'g64', 't64'}

    def load(self) -> None:
        self.titles = set()

        with self.install_path.open() as file:
            rows = csv.reader(file)
            for row in rows:
                # There are some extraneous rows, so we double check that there's enough
                # data in the row as a safety check before attempting to parse
                if len(row) > self.COLUMN_TYPE:
                    archive_type = row[self.COLUMN_TYPE]
                    if archive_type in self.VALID_TYPES:
                        # Only select characters up to the parens
                        title = self.TITLE_MATCH_REGEX.search(row[self.COLUMN_TITLE]).group().strip()
                        self.titles.add(self._clean_title(title))

    def update(self, machine: Machine) -> None:
        if self._clean_title(machine.title) in self.titles:
            machine.collections.add('C64 Dreams')

    # Builds a title that is consistent between the DAT and the C64 Dreams spreadsheet
    def _clean_title(self, title: str) -> str:
        return self.TITLE_CLEAN_REGEX.sub('', title.lower())
