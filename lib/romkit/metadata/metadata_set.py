from __future__ import annotations

from romkit.models.machine import Machine

import json
from pathlib import Path
from typing import Type

# Represents a collection of external metadata loaders
class MetadataSet:
    def __init__(self, path: Path, config: dict) -> None:
        self.config = config
        self.data = {}
        self.metadatas = []

        # Populate metadata based on the provided path
        with path.open() as file:
            self.data = json.load(file)

            # Add machine-specific overrides that differ from the parent
            for key, metadata in self.data.items():
                if 'group' in metadata:
                    self.data[key] = {**self.data[metadata['group']], **metadata}

    # Builds a MetadataSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_metadata: set) -> MetadataSet:
        metadata_set = cls(Path(json['path']), json)

        for metadata_cls in supported_metadata:
            metadata_set.append(metadata_cls)

        return metadata_set

    # Adds a new metadata loader
    def append(self, metadata_cls: Type[BaseMetadata]) -> None:
        metadata_config = self.config.get(metadata_cls.name, {})
        self.metadatas.append(metadata_cls(self.data, metadata_config))

    # Updates the metadata on the given machine
    def update(self, machine: Machine) -> None:
        for metadata in self.metadatas:
            metadata.find_and_update(machine)
