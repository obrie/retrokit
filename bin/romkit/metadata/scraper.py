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
            self.metadata = json.load(file)

    def update(self, machine: Machine) -> None:
        # We look at both self and parent just in case there's an override for
        # a clone or the parent/clone hierarchy has changed
        data = self.metadata.get(machine.title) or self.metadata.get(machine.parent_title)
        if data:
            if 'genres' in data:
                machine.genres.update(data['genres'])

            machine.rating = data.get('rating')
