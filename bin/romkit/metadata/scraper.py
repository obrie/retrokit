from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv
import json
import re
from pathlib import Path

# Scraper metadata managed by Skyscraper's scraping modules
# 
# Format: JSON
class ScraperMetadata(ExternalMetadata):
    name = 'scraper'

    def load(self) -> None:
        with self.install_path.open() as file:
            self.metadata = json.load(file)

    def update(self, machine: Machine) -> None:
        data = self.metadata.get(machine.group_name)
        if data:
            if 'genres' in data:
                machine.genres.update(data['genres'])

            machine.rating = data.get('rating')
