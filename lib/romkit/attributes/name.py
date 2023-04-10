from __future__ import annotations

from romkit.attributes.base import BaseAttribute

import re
from typing import Set

# Machine name
class NameAttribute(BaseAttribute):
    rule_name = 'names'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.name


# Machine title
class TitleAttribute(BaseAttribute):
    rule_name = 'titles'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.title


# Machine disc title
class DiscTitleAttribute(BaseAttribute):
    rule_name = 'disc_titles'
    data_type = str

    def get(self, machine: Machine) -> str:
        return machine.disc_title


# Best-guess version number in the title
# 
# This just looks for the first numeric value in the title and considers
# that to be the "version".
class VersionAttribute(BaseAttribute):
    rule_name = 'versions'
    data_type = float

    # Semantic versioning, e.g. v1.2
    SEMANTIC_VERSION_REGEX = re.compile(r'[Vv ]([0-9]+\.[0-9]*)')

    # Number that's not a part of a word, e.g. '99 or 1999
    NUMBER_REGEX = re.compile(r"[ ']([0-9]+)($|[^A-Za-z])")

    def get(self, machine: Machine) -> float:
        number_match = self.SEMANTIC_VERSION_REGEX.search(machine.title) or self.NUMBER_REGEX.search(machine.title)
        if number_match:
            return float(number_match.group(1))
        else:
            return 0.0
