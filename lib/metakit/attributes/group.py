from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class GroupAttribute(BaseAttribute):
    name = 'group'
    supports_overrides = False

    def get(self, key, metadata) -> str:
        return metadata.get(self.name, key)

    def validate(self, value: str, validation: ValidationResults) -> None:
        if not value or not isinstance(value, str):
            validation.error('group is blank')

        if value not in self.romkit.resolved_groups:
            validation.error(f"group not valid: {value}")
