from __future__ import annotations

from romkit.util import Downloader
from romkit.util.dict_utils import slice_only

import logging
import tempfile
import time
from pathlib import Path
from typing import Dict, List, Type

# Provies a base class for discovery URL paths for romsets
class BaseDiscovery:
    name = None

    def __init__(self,
        urls: List[str],
        match: str,
        ttl: int = 86400,
        downloader: Downloader = Downloader.instance(),
    ):
        self.urls = urls
        self.match = match
        self.ttl = ttl
        self.downloader = downloader
        self.download_dir = Path(f'{tempfile.gettempdir()}/discovery/{self.name}')
        self._loaded = False

    # Builds a Discovery generator from the given JSON data
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> BaseDiscovery:
        return cls.for_name(json['type'])(
            **slice_only(json, ['urls', 'match']),
            **kwargs,
        )

    # Looks up the discovery from the given name
    @classmethod
    def for_name(cls, name) -> Type[BaseDiscovery]:
        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls

        raise Exception(f'Invalid discovery: {name}')

    # Discover mappings for the configured paths in thise Discovery object
    def mappings(self, context) -> Dict[str, str]:
        if not self._loaded:
            self.load()
            self._loaded = True

        return {'url': self.discover(context) or ''}

    # Downloads the given source url
    def download(self, source: str, target: Path) -> None:
        if not target.exists():
            self.downloader.get(source, target, force=True)
        elif (time.time() - target.stat().st_mtime) >= self.ttl:
            try:
                self.downloader.get(source, target, force=True)
            except Exception as e:
                logging.debug(f'Failed to refresh discovery source: {source}')

    # Loads the data needed for discovery
    def load(self) -> None:
        pass

    # Finds the paths associated with the given context
    def discover(self, context: dict) -> Dict[str, str]:
        pass
