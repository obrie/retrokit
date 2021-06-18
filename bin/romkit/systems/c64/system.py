from romkit.systems.base import BaseSystem
from romkit.systems.c64.metadata import C64DreamsMetadata

class C64System(BaseSystem):
    name = 'c64'
    supported_metadata = BaseSystem.supported_metadata + [
        C64DreamsMetadata,
    ]
