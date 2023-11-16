from __future__ import annotations

from romkit.resources.downloader import Downloader
from romkit.util.dict_utils import slice_only

import logging
import re
import tempfile
import time
from collections import defaultdict
from pathlib import Path
from urllib.parse import quote, urljoin, urlparse
from typing import Dict, List, Type

# Provies a base class for discovery URL paths for romsets
class BaseDiscovery:
    name = None

    def __init__(self,
        urls: List[str],
        match: Dict[str, str],
        ttl: int = 86400,
        downloader: Downloader = Downloader.instance(),
    ):
        # Remove empty / blank urls
        self.urls = [url for url in urls if url]
        self.match_patterns = {name: re.compile(pattern) for name, pattern in match.items()}

        # Download info
        self.ttl = ttl
        self.downloader = downloader
        self.download_dir = Path(f'{tempfile.gettempdir()}/discovery/{self.name}')

        # Processed global / machine mappings
        self._loaded = False
        self._default_mappings = {'url': ''}
        self._machine_mappings = defaultdict(dict)
        self._mapping_context_keys = set()

        self.has_missing_urls = not(self.urls and self.urls == urls)

    # Builds a Discovery generator from the given JSON data
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> BaseDiscovery:
        discovery_cls = cls.for_name(json['type'])
        return discovery_cls(
            **slice_only(json, ['urls', 'match', 'ttl']),
            **discovery_cls.parse_extra_args(json),
            **kwargs,
        )

    # Build additional arguments for constructing this class
    @classmethod
    def parse_extra_args(cls, json: dict) -> dict:
        return {}

    # Looks up the discovery from the given name
    @classmethod
    def for_name(cls, name) -> Type[BaseDiscovery]:
        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls

        raise Exception(f'Invalid discovery: {name}')

    # Populates the list of url mappings to use based on paths discovered
    # in the source urls
    def load(self) -> None:
        if not self.urls:
            logging.debug(f'No urls provided for discovery')

        for url in self.urls:
            # Ensure the url is valid
            if not urlparse(url).scheme:
                logging.debug(f'Unable to run discovery for {url}')
                continue

            self.load_url(url)

        self._loaded = True

    def load_url(self, url: str) -> None:
        for path in self.list_paths(url):
            for match_name, match_pattern in self.match_patterns.items():
                result = match_pattern.search(path)
                if not result:
                    continue
                mapping_name = ''.join(result.groups())
                capture_groups_by_name = result.groupdict()

                # Build the url
                discovered_url = urljoin(f'{url}/', quote(path))

                # Track either a machine-specific url or a default url
                if 'machine' in capture_groups_by_name:
                    stored_mappings = self._machine_mappings[mapping_name]
                    self._mapping_context_keys.add('machine')
                elif 'primary_rom' in capture_groups_by_name:
                    stored_mappings = self._machine_mappings[mapping_name]
                    self._mapping_context_keys.add('primary_rom')
                else:
                    stored_mappings = self._default_mappings

                stored_mappings[match_name] = discovered_url

    # Discover mappings for the configured paths in thise Discovery object
    def mappings(self, context: dict) -> Dict[str, str]:
        if not self._loaded:
            self.load()

        result = self._default_mappings.copy()

        machine_names = []
        if 'machine' in self._mapping_context_keys:
            if 'machine' in context:
                machine_names.append(context['machine'])

            if 'machine_alt_names' in context:
                machine_names.extend(context['machine_alt_names'])

        if 'primary_rom' in self._mapping_context_keys:
            if 'primary_rom' in context:
                machine_names.append(context['primary_rom'])

        for machine_name in machine_names:
            if machine_name in self._machine_mappings:
                result = {**result, **self._machine_mappings[machine_name]}
                break

        return result

    # Generates a list of machine names that have been discovered in the source urls
    def machine_keys(self) -> Set[str]:
        return set(self._machine_mappings.keys())

    # Downloads the given source unless it exists and is within the configured TTL
    def update(self, source: str, filename: str, do_update = None) -> None:
        if not do_update:
            do_update = self.download

        self.download_dir.mkdir(parents=True, exist_ok=True)
        target = self.download_dir.joinpath(filename)

        if not target.exists():
            do_update(source, target)
        elif (time.time() - target.stat().st_mtime) >= self.ttl:
            try:
                do_update(source, target)
            except Exception as e:
                logging.debug(f'Failed to refresh discovery source: {source}')

    # Downloads the given source url to the path
    def download(self, source: str, target: Path) -> None:
        self.downloader.get(source, target, force=True)

    # Loads the list of potential paths to match.  These should be *relative* to the
    # provided URL.
    def list_paths(self, url: str) -> List[str]:
        return []
