from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import json

# Custom collections
# 
# Format: JSON
class CollectionsMetadata(ExternalMetadata):
    name = 'collections'

    def load(self) -> None:
        self.collections = {}

        with self.install_path.open() as file:
            collection_to_titles = json.load(file)
            for collection, titles in collection_to_titles.items():
                self.collections[collection] = set(titles)

    def update(self, machine: Machine) -> None:
        collections = set()

        for collection, titles in self.collections.items():
            # Look at both self and parent just in case there's an override for the clone
            if machine.title in titles or machine.parent_title in titles:
                collections.add(collection)

        machine.collections = collections
