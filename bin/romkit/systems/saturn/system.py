from __future__ import annotations

from romkit.systems.base import BaseSystem
from romkit.systems.saturn.filters import CompatibilityRatingFilter

class SaturnSystem(BaseSystem):
    name = 'saturn'

    supported_filters = BaseSystem.supported_filters + [
        CompatibilityRatingFilter,
    ]
