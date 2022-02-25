from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import json

# Scraper metadata managed by Skyscraper's scraping modules
# 
# Format: JSON
class ScraperMetadata(ExternalMetadata):
    name = 'scraper'

    def load(self) -> None:
        with self.install_path.open() as file:
            for key, metadata in json.load(file).items():
                self.set_data(key, metadata)

    def update(self, machine: Machine) -> None:
        metadata = self.get_data(machine)
        if metadata:
            if 'genres' in metadata:
                machine.genres.update(metadata['genres'])

            machine.rating = metadata.get('rating')
