from __future__ import annotations

from romkit.filters.base import BaseFilter

from typing import Set

# Filter on the year
class YearFilter(BaseFilter):
    name = 'years'

    def values(self, machine: Machine) -> Set[str]:
        if machine.year:
            return {machine.year}
        else:
            return self.empty

# Filter on the developer
class DeveloperFilter(BaseFilter):
    name = 'developers'

    def values(self, machine: Machine) -> Set[str]:
        if machine.developer:
            return {machine.developer}
        else:
            return self.empty

# Filter on the publisher
class PublisherFilter(BaseFilter):
    name = 'publishers'

    def values(self, machine: Machine) -> Set[str]:
        if machine.publisher:
            return {machine.publisher}
        else:
            return self.empty
