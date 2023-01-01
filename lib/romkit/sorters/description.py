from __future__ import annotations

from romkit.sorters.base import BaseSorter

import re

# Sort on presence of keywords in the name
class KeywordSorter(BaseSorter):
    name = 'keywords'

    def value(self, machine: Machine) -> str:
        return f'{machine.description} ({machine.comment})'


# Sort on presence of flags in the name
class FlagSorter(BaseSorter):
    name = 'flags'

    def value(self, machine: Machine) -> str:
        return machine.flags_str

# Sort on number of flags matched in the name
class FlagsCountSorter(BaseSorter):
    name = 'flags_count'

    def value(self, machine: Machine) -> int:
        return len(list(filter(lambda flag: flag in machine.flags_str, self.setting)))

# Sort on total number of flag groups in the name
class FlagGroupsTotalSorter(BaseSorter):
    name = 'flag_groups_total'

    def value(self, machine: Machine) -> int:
        return machine.flags_str.count('(')

# Sort based on a best-guess version number in the title
# 
# This just looks for the first numeric value in the title and considers
# that to be the "version".
class VersionSorter(BaseSorter):
    name = 'version'
    NUMBER_REGEX = re.compile(r'[0-9]+')

    def value(self, machine: Machine) -> int:
        number_match = self.NUMBER_REGEX.search(machine.title)
        if number_match:
            return int(number_match.group())
        else:
            return 0
