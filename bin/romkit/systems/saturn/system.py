from __future__ import annotations

from romkit.systems.base import BaseSystem
from romkit.systems.saturn.metadata import EmulatorRatingMetadata

class SaturnSystem(BaseSystem):
    name = 'saturn'

    supported_metadata = BaseSystem.supported_metadata + [
        EmulatorRatingMetadata,
    ]
