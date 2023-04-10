from __future__ import annotations

from romkit.attributes.base import BaseAttribute

# Language(s) used by the game, assuming it can't be identified by the name
class LanguagesAttribute(BaseAttribute):
    metadata_name = 'languages'
    rule_name = metadata_name
    data_type = str

    def set(self, machine: Machine, languages: List[str]) -> None:
        machine.languages.update(languages)

    def get(self, machine: Machine) -> Set[str]:
        return machine.languages
