from __future__ import annotations

from romkit.filters import FilterSet
from romkit.models.collection import Collection

from typing import Type

# Represents a collection of external metadata loaders
class CollectionSet:
    def __init__(self) -> None:
        self.collections = []

    # Builds a CollectionSet from the given json data
    @classmethod
    def from_json(cls, json: dict, config: dict, supported_filters: list) -> CollectionSet:
        collection_set = cls()

        for collection_config in json:
            filter_set = FilterSet.from_json(collection_config['filters'], config, supported_filters, log=False)
            collection = Collection(collection_config['name'], filter_set)
            collection_set.add(collection)

        return collection_set

    # Associates the key with the given data.
    # 
    # This will also associate the normalized key in case there are any differences
    # between the data we have and what's in the romset.
    def add(self, collection: Collection) -> None:
        self.collections.append(collection)

    # Lists the collections that are associated with this machine
    def list(self, machine: Machine) -> Set[str]:
        return set([collection.name for collection in self.collections if collection.allow(machine)])
