from __future__ import annotations

from metakit.attributes.base import BaseAttribute
from metakit.models.language import Language

class LanguagesAttribute(BaseAttribute):
    name = 'languages'

    def validate(self, value: List[str]) -> List[str]:
        errors = []

        for code in value:
            if code not in Language.CODES:
                errors.append(f'language not valid: {code}')

        return errors

    def format(self, value: List[str]) -> List[str]:
        return self._sort_list(value)
