from romkit.systems import BaseSystem
from romkit.filters.arcade import LanguageFilter, CategoryFilter, RatingFilter, EmulatorFilter

class PCSystem(BaseSystem):
    name = 'pc'

    def enable(self, machine, dirname):
        # TODO: Create configuration file
        pass
