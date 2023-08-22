from __future__ import annotations

import itertools
import json
import logging
from pathlib import Path
from typing import Dict, List, Optional, Set

from metakit.attributes import __all_attributes__, BaseAttribute
from metakit.models.romkit import ROMKit
from romkit.models.machine import Machine

# Represents a metadata database for a system
class Database:
    def __init__(self, romkit: ROMKit, config: dict) -> None:
        self.romkit = romkit
        self.attributes = [attribute_cls(romkit, config) for attribute_cls in __all_attributes__]

        # Open the dataset
        self.path = Path(config['metadata']['path'])
        self.reload()

    # Loads the dataset into memory.  If previously opened, the dataset will be overwritten.
    def reload(self) -> None:
        with self.path.open() as f:
            self.dataset = json.load(f)

    # Look up the given attribute by name
    def attribute(self, name: str) -> BaseAttribute:
        return next((attribute_cls for attribute_cls in self.attributes if attribute_cls.name == name))

    # Gets the list of keys used in this database.
    def keys(self) -> Set[str]:
        return self.dataset.keys()

    # Gets the list of groups currently used in this database.  This does *not* include
    # keys that are just extensions of existing groups.
    @property
    def groups(self) -> Set[str]:
        groups = set()
        for key, metadata in self.dataset.items():
            if 'group' not in metadata:
                groups.add(key)
        return groups

    # Whether the given key exists in this database
    def exists(self, key) -> bool:
        return key in self.dataset

    # Gets the first dataset entry that matches one of the given keys
    def get(self, *keys) -> Optional[dict]:
        for key in keys:
            if key in self.dataset:
                return self.dataset[key]

    # Overrides the given key with new metadata
    def set(self, key: str, metadata: dict) -> None:
        self.dataset[key] = metadata

    # Updates the given key with new metadata
    def update(self, key: str, metadata: dict) -> None:
        if key not in self.dataset:
            self.dataset[key] = {}

        self.dataset[key].update(metadata)

    # Deletes the given key from the database
    def delete(self, key: str) -> None:
        del self.dataset[key]

    # Deletes an attribute from the metadata associated with the given key
    def delete_attribute(self, key: str, attribute_name: str) -> None:
        metadata = self.get(key)
        if metadata and attribute_name in metadata:
            del metadata[attribute_name]

            if 'group' in metadata and len(metadata) == 1:
                self.delete(key)

    # Migrates metadata from one key value to another
    def migrate(self, from_key: str, to_key: str) -> None:
        source_metadata = self.get(from_key)
        target_metadata = self.get(to_key)

        if target_metadata and from_key in self.romkit.keys:
            # Ensure there's no group override in the target
            target_metadata.pop('group', None)

            # Old key is still valid and isn't just a strict rename.  We need to
            # do a swap while making a best effort at keeping overrides in tact.
            overlapping_keys = set(source_metadata.keys()).intersection(target_metadata.keys())
            new_source_metadata = {'group': to_key}
            for key in overlapping_keys:
                new_source_metadata[key] = source_metadata[key]
                del source_metadata[key]

            self.set(from_key, new_source_metadata)
        else:
            # Old key is no longer valid
            self.delete(from_key)

        # Migrate attributes
        for attribute in self.attributes:
            attribute.migrate_metadata(from_key, to_key, source_metadata)

        # Migrate overrides tied to the group being migrated
        for other_key, other_metadata in self.dataset.items():
            if other_metadata.get('group') == from_key:
                logging.info(f'[{to_key}] [group] Updated {other_key}')
                other_metadata['group'] = to_key

        self.update(to_key, source_metadata)

    # Updates the group identifiers used to help with migrations during date updates
    def update_metadata_from_romkit(self) -> None:
        self.romkit.load()

        for attribute in self.attributes:
            if not attribute.set_from_machine:
                continue

            for group, machine in self.romkit.resolved_group_to_machine.items():
                metadata = self.dataset[group]
                attribute.set(metadata, machine, self.romkit.find_machines_by_group(group))

    # Cleans up attribute values in the database based on the current DAT.
    # 
    # This is typically run after a merge.
    def clean(self) -> None:
        for key, metadata in self.dataset.items():
            for attribute in self.attributes:
                attribute.clean_metadata(key, metadata)

    # Validates that this database is properly implemented by checking all values
    # and grous defined in it
    def validate(self, target_groups: set = None) -> Dict[str, List[str]]:
        self.romkit.load()

        errors = {}

        # Check metadata values
        for key, metadata in self.dataset.items():
            for attribute in self.attributes:
                key_errors = attribute.validate_metadata(key, metadata)
                if key_errors:
                    errors[key] = key_errors

        # Check expected groups
        for group in (target_groups or self.romkit.resolved_groups):
            if not self.exists(group):
                errors[group] = ['Missing']

        return errors

    # Generates a dictionary for attempting to find a key in the database
    # based on some other piece of metadata, such as:
    # * The machine id
    # * The normalized key name
    @property
    def indexed_table(self) -> Dict[str, str]:
        self.romkit.load()

        mappings = {}

        for key, metadata in self.dataset.items():
            mappings[key] = key
            mappings[Machine.normalize(key)] = key

            if 'id' in metadata:
                mappings[metadata['id']] = key

        return mappings

    # Analyzes the current database against the given set of target groups,
    # generating a report that indicates how we should update the keys.
    def build_migration_plan(self, target_groups: set = None) -> Dict[str, str]:
        self.romkit.load()
        if target_groups is None:
            target_groups = self.romkit.resolved_groups

        # Generate a lookup table for helping migrate
        lookup_table = self.indexed_table

        migration_plan = {}

        # Generate a report for what we should do with the current keys in the
        # dataset based on the new target groups
        for group in sorted(target_groups):
            # Short circuit if group hasn't changed
            if self.exists(group):
                original_key = self.get(group).get('group', group)
                if original_key != group:
                    migration_plan[original_key] = group

                continue

            # Try to find the original key, attempting by:
            # * Unique, predetermined id for any grouped machine
            # * Normalized group
            # 
            # We don't need to look up the group again because we've already short-circuited
            # with that logic above.
            original_key = None
            machines = self.romkit.find_machines_by_group(group)
            lookup_values = [machine.id for machine in machines] + [Machine.normalize(group)]
            for value in lookup_values:
                key = lookup_table.get(value)
                metadata = self.get(key)

                if metadata is None or 'group' in metadata:
                    # There's a group override or we're not tracking this key.
                    # Ignore it.
                    continue
                else:
                    original_key = key
                    break

            if original_key and self.exists(original_key) and original_key not in migration_plan:
                migration_plan[original_key] = group
            else:
                migration_plan[group] = group

        # Mark invalid keys as not having a corresponding target
        for key, metadata in self.dataset.items():
            group = metadata.get('group', key)
            if group not in target_groups and migration_plan.get(group) == None:
                migration_plan[key] = None

        return migration_plan

    # Saves the current database to the same path it was read from
    def save(self) -> None:
        with self.path.open('w', encoding='utf8') as f:
            json.dump(self.serialize(), f, ensure_ascii=False, indent=2)

    # Generates the JSON data to use when writing the database.
    # 
    # This will ensure that the data is consistently formatted.
    def serialize(self) -> None:
        serialized_data = {}

        # Add metadata sorted by key
        for key in sorted(self.keys()):
            metadata = self.dataset[key]
            metadata_attrs = sorted(metadata.keys())

            new_metadata = serialized_data[key] = {}

            # Format attributes within the metadata
            for attribute in self.attributes:
                merge_attr_name = f'{attribute.name}|'
                replace_attr_name = f'{attribute.name}~'

                for attr_name in metadata_attrs:
                    if attr_name == attribute.name or attr_name.startswith(merge_attr_name) or attr_name.startswith(replace_attr_name):
                        value = metadata[attr_name]
                        if value or value == False or value == 0:
                            new_metadata[attr_name] = attribute.format(value)

        # Post-process: remove equivalent keys between parent and clone
        for key in list(serialized_data.keys()):
            metadata = serialized_data[key]
            group = metadata.get('group')
            if not group:
                continue

            for attribute in self.attributes:
                if attribute.name not in metadata:
                    continue

                # If the same value is shared by its group, then we don't need it here
                value = metadata.get(attribute.name)
                if value == serialized_data[group].get(attribute.name):
                    del metadata[attribute.name]

            if len(metadata) == 1:
                del serialized_data[key]

        return serialized_data
