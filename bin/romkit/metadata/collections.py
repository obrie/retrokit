from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import json

# Custom collections
# 
# Format: JSON
class CollectionsMetadata(ExternalMetadata):
    name = 'collections'

    def load(self) -> None:
        with self.install_path.open() as file:
            collection_to_keys = json.load(file)
            for collection, keys in collection_to_keys.items():
                for key in keys:
                    if key not in self.data:
                        self.set_data(key, set())

                    self.data[key].add(collection)

    def update(self, machine: Machine) -> None:
        collections = self.get_data(machine)
        if collections:
            machine.collections = collections
