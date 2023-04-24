from __future__ import annotations

import logging

from romkit.models.machine import Machine
from metakit.attributes.base import BaseAttribute

class MergeAttribute(BaseAttribute):
    name = 'merge'

    def validate(self, value: List[str]) -> List[str]:
        errors = []

        for merge_key in value:
            if not self._is_valid_merge_key(merge_key):
                errors.append(f"merge key not found: {merge_key}")

        return errors

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)

    # Migrates the list of machine keys (name/title/disc) to merge based on the
    # new group being used.
    def migrate(self, from_group: str, to_group: str, value: List[str]) -> None:
        normalized_from_group = Machine.normalize(from_group)
        normalized_to_group = Machine.normalize(to_group)

        for merge_key in value:
            normalized_merge_key = Machine.normalize(merge_key)
            if normalized_merge_key == normalized_to_group:
                # This key will be automatically merged by romkit.  No
                # need to call it out separately anymore.
                logging.info(f'[{from_group}] [merge] Removed {merge_key}')
                value.remove(merge_key)

        if normalized_from_group != normalized_to_group and self._is_valid_merge_key(from_group):
            # This is still a valid merge key, but we can't trust it yet.  We have
            # to check whether it's tied to a parent or not.
            machine = next((machine for machine in self.romkit.machines.all() if machine.name == from_group or machine.disc_title == from_group or machine.title == from_group), None)
            if machine and not machine.parent_name:
                # The original group needs to be manually merged still
                logging.info(f'[{to_group}] [merge] Added {from_group}')
                value.append(from_group)

    # Is this key allowed to be part of this attribute?
    def _is_valid_merge_key(self, merge_key: str) -> bool:
        return merge_key in self.romkit.keys
