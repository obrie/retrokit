from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Language(s) used by the game, assuming it can't be identified by the name
class LanguagesMetadata(BaseMetadata):
    name = 'languages'

    def update(self, machine: Machine, languages: List[str]) -> None:
        machine.languages.update(languages)
