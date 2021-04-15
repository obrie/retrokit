from __future__ import annotations

from romkit.util import Downloader

import logging
import re
import tempfile
import time
from pathlib import Path
from typing import Dict, Type

# Provies a base class for discovery URL paths for romsets
class BaseDiscovery:
    name = None

    def __init__(self,
        base_url: str,
        metadata_url: str,
        paths: Dict[str, str],
        ttl: int = 86400,
        downloader: Downloader = Downloader.instance(),
    ):
        self.base_url = base_url
        self.metadata_url = metadata_url.format(base=base_url)
        self.paths = paths
        self.ttl = ttl
        self.downloader = downloader
        self.download_dir = Path(f'{tempfile.gettempdir()}/discovery/{self.name}')
        self._mappings = None

    # Builds a Discovery generator from the given JSON data
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> BaseDiscovery:
        return cls.for_name(json['type'])(
            json['base'],
            json['metadata'],
            json['paths'],
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
    def mappings(self) -> Dict[str, str]:
        if not self._mappings:
            self.load()
            self._mappings = {}

            for name, pattern in self.paths.items():
                self._mappings[name] = self.discover(re.compile(pattern))

        return self._mappings

    # Downloads the given source url
    def download(self, source: str, target: Path) -> None:
        if not target.exists() or (time.time() - target.stat().st_mtime) >= self.ttl:
            self.downloader.get(source, target, force=True)

    # Loads the data needed for discovery
    def load(self) -> None:
        pass

    # Finds the path associated with the given pattern
    def discover(self, pattern: str) -> str:
        pass
