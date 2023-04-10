from __future__ import annotations

from romkit.models.collection import Collection
from romkit.processing.ruleset import Ruleset

# Represents a collection of external metadata loaders
class CollectionSet:
    def __init__(self) -> None:
        self.collections = []

    # Builds a CollectionSet from the given json data
    @classmethod
    def from_json(cls, json: dict, attributes: List[BaseAttribute], **kwargs) -> CollectionSet:
        collection_set = cls(**kwargs)

        for name, collection_config in json.items():
            ruleset = Ruleset.from_json(collection_config['filters'], attributes)
            collection = Collection(name, ruleset)
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
        return {collection.name for collection in self.collections if collection.match(machine)}
