from __future__ import annotations

from romkit.systems.base import BaseSystem
from romkit.systems.psx.metadata import DuckstationMetadata

class PSXSystem(BaseSystem):
    name = 'psx'

    supported_metadata = BaseSystem.supported_metadata + [
        DuckstationMetadata,
    ]
