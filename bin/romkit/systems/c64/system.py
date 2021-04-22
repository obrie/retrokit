from romkit.systems.base import BaseSystem
from romkit.systems.c64.filters import C64DreamsFilter

class C64System(BaseSystem):
    name = 'c64'
    dynamic_filters = BaseSystem.dynamic_filters + [
        C64DreamsFilter,
    ]
