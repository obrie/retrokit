from __future__ import annotations

from romkit.systems.base import BaseSystem

class PSPSystem(BaseSystem):
    name = 'psp'

    # The end of the name range in each page
    PAGE_1_END = 'L'

    # Additional context for rendering Machine URLs
    def context_for(self, machine: Machine) -> dict:
        first_letter = machine.name[0].upper()
        if first_letter <= self.PAGE_1_END:
            page_number = ''
        else:
            page_number = '.p2'

        return {'page_number': page_number}
