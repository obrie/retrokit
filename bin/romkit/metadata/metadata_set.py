from __future__ import annotations

# Represents a collection of external metadata loaders
class MetadataSet:
    def __init__(self) -> None:
        self.metadatas = []

    # Builds a MetadataSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_metadata: set) -> MetadataSet:
        metadata_set = cls()

        for metadata_cls in supported_metadata:
            config = json.get(metadata_cls.name)
            if config:
                metadata_set.append(metadata_cls(config))

        return metadata_set

    # Adds a new metadata loader
    def append(self, metadata: ExternalMetadata) -> None:
        self.metadatas.append(metadata)

    # Adds a new filter
    def update(self, machine: Machine) -> None:
        for metadata in self.metadatas:
            metadata.update(machine)
