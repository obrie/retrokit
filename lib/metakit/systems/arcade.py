from __future__ import annotations

from metakit.systems.base import BaseSystem
from metakit.systems.arcade_data import __all_external_data__

class ArcadeSystem(BaseSystem):
    name = 'arcade'

    # Caches external data used by the system, forcing it to be re-downloaded if
    # requested.
    def cache_external_data(self, refresh: bool = False) -> None:
        for external_data in __all_external_data__:
            external_data().download(force=refresh)

    # Skip
    def scrape(self, **kwargs) -> None:
        pass

    # Update metadata from the exodos database
    def update_metadata(self) -> None:
        self.romkit.load()
        for external_data in __all_external_data__:
            external_data().update(self.database)
