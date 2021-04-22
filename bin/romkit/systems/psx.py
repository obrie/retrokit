from __future__ import annotations

from romkit.systems import BaseSystem

class PSXSystem(BaseSystem):
    name = 'psx'

    # The end of the name range in each page
    PAGE_1_END = 'F'
    PAGE_2_END = 'O'
    PAGE_3_END = 'S'

    # Additional context for rendering Machine URLs
    def context_for(self, machine: Machine) -> dict:
        first_letter = machine.name[0].upper()
        if first_letter <= self.PAGE_1_END:
            page_number = ''
        elif first_letter <= self.PAGE_2_END:
            page_number = '.p2'
        elif first_letter <= self.PAGE_3_END:
            page_number = '.p3'
        else:
            page_number = '.p4'

        return {'page_number': page_number}
