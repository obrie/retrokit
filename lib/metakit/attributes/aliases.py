from __future__ import annotations

from metakit.attributes.base import BaseAttribute

class AliasesAttribute(BaseAttribute):
    name = 'aliases'
    set_from_machine = True

    def validate(self, value: List[str], validation: ValidationResults) -> None:
        if not all(alias and isinstance(alias, str) for alias in value):
            validation.error(f'aliases must contain non-empty strings: {value}')

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)

    def clean_metadata(self, group: str, metadata: dict) -> None:
        if 'group' in metadata:
            del metadata[self.name]

        value = metadata.get(self.name)
        if value:
            value.remove(group)

    def get_from_machine(self, machine: Machine, grouped_machines: List[Machine]) -> List[str]:
        aliases = {
            grouped_machine.title
            for grouped_machine in grouped_machines
            if grouped_machine.title != machine.title and grouped_machine.is_clone
        }
        return list(aliases)

    def set(self, metadata: dict, machine: Machine, grouped_machines: List[Machine]) -> None:
        aliases = self.get_from_machine(machine, grouped_machines)

        # Use the metadata context to skip aliases for merge values, since that's already
        # assumed
        if 'merge' in metadata:
            aliases = [alias for alias in aliases if alias not in metadata['merge']]

        metadata[self.name] = aliases
