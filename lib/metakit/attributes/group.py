from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class GroupAttribute(BaseAttribute):
    name = 'group'
    supports_overrides = False

    def value_from(self, key, metadata) -> str:
        return metadata.get(self.name, key)

    def validate(self, value: str) -> List[str]:
        errors = []

        if not value or not isinstance(value, str):
            errors.append('group is blank')

        if value not in self.romkit.resolved_groups:
            errors.append(f"group not valid: {value}")

        return errors
