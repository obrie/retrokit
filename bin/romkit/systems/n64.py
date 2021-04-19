from romkit.systems import BaseSystem
from romkit.filters.n64 import EmulatorFilter

class N64System(BaseSystem):
    name = 'n64'
    static_filters = BaseSystem.static_filters + [
        EmulatorFilter,
    ]
