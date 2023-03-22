from __future__ import annotations

from romkit.models.machine import Machine

import json
from pathlib import Path
from typing import Optional, Type

# Represents a collection of external metadata loaders
class MetadataSet:
    def __init__(self,
        path: Optional[Path],
        defaults: dict = {},
        config: dict = {},
    ) -> None:
        self.config = config
        self.data = {}
        self.defaults = defaults
        self.metadatas = []

        # Populate metadata based on the provided path
        if path:
            with path.open() as file:
                self.data = json.load(file)

                # Resolve dynamically generated metadata
                for key in list(self.data.keys()):
                    self._resolve_metadata(key)

    # Builds a MetadataSet from the given json data
    @classmethod
    def from_json(cls, json: dict, supported_metadata: set) -> MetadataSet:
        path = json.get('path')
        defaults = json.get('defaults', {})
        metadata_set = cls(path and Path(path), defaults, json)

        for metadata_cls in supported_metadata:
            metadata_set.append(metadata_cls)

        return metadata_set

    # Adds a new metadata loader
    def append(self, metadata_cls: Type[BaseMetadata]) -> None:
        metadata_config = self.config.get(metadata_cls.name, {})
        self.metadatas.append(metadata_cls(self.data, self.defaults, metadata_config))

    # Updates the metadata on the given machine
    def update(self, machine: Machine) -> None:
        for metadata in self.metadatas:
            metadata.find_and_update(machine)

    # Compact metadata attributes by flattening merge values down to
    # their base attribute name
    def _resolve_metadata(self, key: str) -> None:
        metadata = self.data[key]

        # Merge in parent meadata
        if 'group' in metadata:
            metadata = {**self.defaults, **self.data[metadata['group']], **metadata}
        else:
            metadata = {**self.defaults, **metadata}

        # Merge individual attributes
        for attr_name in list(metadata.keys()):
            value_to_merge = metadata[attr_name]
            merge_char_index = attr_name.find('|')

            if merge_char_index != -1:
                reference_attr_name = attr_name[0:merge_char_index]
                reference_value = metadata.get(reference_attr_name)

                if reference_value is None:
                    metadata[reference_attr_name] = value_to_merge
                elif isinstance(reference_value, list):
                    reference_value.extend(value_to_merge)
                elif isinstance(reference_value, dict):
                    reference_value.update(value_to_merge)
                else:
                    metadata[reference_attr_name] = value_to_merge

        self.data[key] = metadata
