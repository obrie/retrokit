from __future__ import annotations
from typing import Optional

# Provides a base class for loading machine-level attributes outside the system dat
class BaseAttribute:
    name = None
    supports_overrides = True

    def __init__(self, romkit: ROMKit, config: dict) -> None:
        self.romkit = romkit
        self.config = config
        self.load()

    # Whether this attribute must be present on all database entries
    @property
    def required(self) -> bool:
        return False

    # Loads any data needed by this attribute
    def load(self) -> None:
        pass

    # Validates the given key / value in the database
    def validate_metadata(self, key, metadata) -> List[str]:
        errors = []

        value = self.value_from(key, metadata)
        if value is not None or self.required:
            new_errors = self.validate(value)
            if new_errors:
                errors.extend(new_errors)

        if self.supports_overrides:
            merge_key = f'{self.name}|'
            for key, value in metadata.items():
                if key.startswith(merge_key) and value is not None:
                    new_errors = self.validate(value)
                    if new_errors:
                        errors.extend(new_errors)

        return errors

    # Gets the value of this attribute from the given metadata
    def value_from(self, key, metadata):
        return metadata.get(self.name)

    # Validates that the given value is valid.
    # 
    # By default, returns true.
    def validate(self, value) -> List[str]:
        pass

    # Formats the given value.
    # 
    # By default, returns the same value unchanged.
    def format(self, value):
        return value

    # Migrates the given metadata for this attribute when moving from one group name to another
    def migrate_metadata(self, from_group: str, to_group: str, metadata: dict) -> None:
        value = self.value_from(to_group, metadata)
        if value:
            self.migrate(from_group, to_group, value)

    # Migrates the metadata value for this attribute when moving from one group name to another
    def migrate(self, from_group: str, to_group: str, value) -> None:
        pass

    # Sorts the keys within the given dictionary based on a predefined order
    def _sort_dict(self, value: dict, key_order: Optional[list] = None) -> dict:
        if key_order:
            key_fn = lambda item: key_order.index(item[0])
        else:
            key_fn = lambda item: item[0]

        return dict(sorted(value.items(), key=key_fn))

    # Sorts the keys in the given list, removing any duplicates
    def _sort_list(self, value: list) -> list:
        return sorted(set(value))
