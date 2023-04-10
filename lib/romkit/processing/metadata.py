from __future__ import annotations

from romkit.models.machine import Machine
from romkit.util.dict_utils import slice_only

import json
from enum import Enum
from pathlib import Path

class MetadataModifier(Enum):
    MERGE = '|'
    REPLACE = '~'


# Represents a metadata database for a system
class Metadata:
    def __init__(self,
        attributes: List[BaseAttribute],
        defaults: dict = {},
    ) -> None:
        self.attributes = [attr for attr in attributes if attr.metadata_name]
        self.defaults = {}
        self.data = {}
        self.mappings = {}

        self.update_defaults(defaults)

    # Builds Metadata from the given json data
    @classmethod
    def from_json(cls, json: Dict[str, Any], attributes: List[BaseAttribute], **kwargs) -> Metadata:
        metadata = cls(attributes=attributes, **slice_only(json, {'defaults'}), **kwargs)

        path = json.get('path')
        if path:
            metadata.load(Path(path))

        return metadata

    # Populate metadata based on the provided path
    def load(self, path: Path) -> None:
        with path.open() as file:
            self.data.update(json.load(file))
            self.index()

    # Resolves dynamically generated metadata and creates an index to map
    # various keys to their associated group name
    def index(self) -> None:
        for key in list(self.data.keys()):
            self._resolve_metadata(key)
            self._create_mappings(key)

    # Looks up the data associated with the given machine.  The following prioritizations
    # will be used when trying to look up the data:
    # 
    # * Machine name (most specific)
    # * Parent name
    # * Parent disc title
    # * Parent title
    # * Disc title
    # * Title (least specific)
    # 
    # We first look for all non-normalized values, then normalized values.
    # 
    # The first match will be returned.
    def get(self, machine: Machine) -> Dict[str, Any]:
        for normalize in [False, True]:
            for key in [machine.name, machine.parent_name, machine.parent_disc_title, machine.parent_title, machine.disc_title, machine.title]:
                if not key:
                    continue

                if normalize:
                    key = Machine.normalize(key)

                data_key = self.mappings.get(key)
                if data_key:
                    return self.data[data_key]

    # Set defaults on the associated attributes
    def update_defaults(self, defaults: Dict[str, Any]) -> None:
        self.defaults = defaults

        for attribute in self.attributes:
            if attribute.metadata_name in self.defaults:
                attribute.default = self.defaults[attribute.metadata_name]

    # Updates the metadata on the given machine
    def update(self, machine: Machine) -> None:
        metadata = self.get(machine)

        for attribute in self.attributes:
            value = metadata and metadata.get(attribute.metadata_name) or attribute.default
            if value is not None:
                attribute.set(machine, value)

    # Compact metadata attributes by flattening merge values down to
    # their base attribute name
    def _resolve_metadata(self, key: str) -> None:
        metadata = self.data[key]

        # Merge in parent meadata
        if 'group' in metadata:
            metadata = {**self.defaults, **self.data[metadata['group']], 'merge': [], **metadata}
        else:
            metadata = {**self.defaults, **metadata, 'group': key}

        # Merge individual attributes
        for attr_name in list(metadata.keys()):
            value_to_merge = metadata[attr_name]
            merge_char_index = attr_name.find(MetadataModifier.MERGE.value)
            replace_char_index = attr_name.find(MetadataModifier.REPLACE.value)

            if merge_char_index != -1:
                reference_attr_name = attr_name[0:merge_char_index]
                reference_value = metadata.get(reference_attr_name)

                if isinstance(reference_value, list):
                    new_value = reference_value + value_to_merge
                elif isinstance(reference_value, dict):
                    new_value = {**reference_value, **value_to_merge}
                else:
                    new_value = value_to_merge

                metadata[reference_attr_name] = new_value
            elif replace_char_index != -1:
                reference_attr_name = attr_name[0:replace_char_index]
                metadata[reference_attr_name] = value_to_merge

        self.data[key] = metadata

    # Maps the given key to its associated metadata key and any other names/titles
    # being merged with it.
    def _create_mappings(self, key: str) -> None:
        self._create_mapping(key, key)

        # Add merge keys to map as well
        metadata = self.data[key]
        if 'merge' in metadata:
            for merge_key in metadata['merge']:
                self._create_mapping(merge_key, key)

    # Maps the given key (a name or title) to a specific metadata key
    # 
    # This maps both the raw key and a normalized version of the key in order to allow for
    # matching when there are minor differences in punctuation
    def _create_mapping(self, key: str, data_key: str) -> None:
        if key not in self.mappings or key == data_key:
            self.mappings[key] = data_key
            self.mappings[Machine.normalize(key)] = data_key
