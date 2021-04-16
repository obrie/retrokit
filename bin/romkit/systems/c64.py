from romkit.systems import BaseSystem
from romkit.filters.c64 import C64DreamsFilter

class C64System(BaseSystem):
    name = 'c64'
    dynamic_filters = BaseSystem.dynamic_filters + [
        C64DreamsFilter,
    ]
