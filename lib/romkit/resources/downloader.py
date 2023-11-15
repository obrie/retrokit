from __future__ import annotations

from romkit.resources.adapters import BaseAdapter
from romkit.resources.middleware import BaseMiddleware
from romkit.resources.session import Session
from romkit.util.dict_utils import deepmerge, slice_only

import logging
import requests
import tempfile
from pathlib import Path
from urllib.parse import urlparse

# Provides requests-like functionality for downloading from different URI schemes
class Downloader:
    _instance = None

    def __init__(self,
        # Backoff factor to apply between attempts
        session: Session = None,
        # Site-specific configuration overrides
        sites: dict = {},
        # Middleware for injecting additional configuration options into requests
        middlewares: List[BaseMiddleware] = [],
    ) -> None:
        self.session = session or Session()
        self.sites = sites
        self.middlewares = middlewares
        self.adapters = {}

        # Build default mapping of adapters for handling different URI schemes
        for adapter in BaseAdapter.__subclasses__():
            adapter_instance = adapter()
            for scheme in adapter.schemes:
                self.mount(scheme, adapter_instance)

    @classmethod
    def instance(cls) -> Downloader:
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
            cls._instance.__init__()
        return cls._instance

    # Builds a new downloader from the given json
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> Downloader:
        if 'middleware' in json:
            middlewares = [BaseMiddleware.from_json(middleware_json) for middleware_json in json['middleware']]
        else:
            middlewares = []

        return cls(
            session=Session.from_json(json),
            middlewares=middlewares,
            **slice_only(json, ['sites']),
            **kwargs,
        )

    # Adds support for processing the given URI scheme with an adapter
    def mount(self, scheme: str, adapter: BaseAdapter) -> None:
        self.adapters[scheme] = adapter

    # Attempts to download from the given source unless either:
    # * It already exists in the destination
    # * The file is being force-refreshed
    def get(self, source: str, destination: Path, force: bool = False) -> None:
        if not source:
            raise requests.exceptions.URLRequired()

        source_uri = urlparse(source)
        adapter = self.adapters[source_uri.scheme]

        # Ensure directory exists
        destination.parent.mkdir(parents=True, exist_ok=True)

        if not destination.exists() or destination.stat().st_size == 0 or force or adapter.force(source, destination):
            # Re-download the file
            logging.debug(f'Downloading {source} to {destination}')
            with tempfile.TemporaryDirectory() as tmp_dir:
                # Initially download to a temporary directory so we don't overwrite until
                # the download is completed successfully
                download_path = Path(tmp_dir).joinpath(destination.name)

                session = self.session.with_overrides(self._overrides_for(source))
                adapter.download(source, download_path, session)

                if download_path.exists() and download_path.stat().st_size > 0:
                    # Rename file to final destination
                    download_path.rename(destination)
                else:
                    download_path.unlink(missing_ok=True)
                    raise requests.exceptions.HTTPError()

    # Looks up the given configuration, scoped to the given site
    def _overrides_for(self, site: str) -> Any:
        site_uri = urlparse(site)
        overrides = {}

        # Merge middleware overrides
        for middleware in self.middlewares:
            if middleware.match(site):
                deepmerge(overrides, middleware.overrides)

        # Merge domain-specific oerrides
        # 
        # Starting with the top-level domain, see if each subdomain has overrides
        # defined for it.  For example, for `a.b.c.com`, we will merge (in order):
        # * c.com
        # * b.c.com
        # * a.b.c.com
        netloc_parts = site_uri.netloc.split('.')
        for index in range(len(netloc_parts) - 2, -1, -1):
            candidate_site = '.'.join(netloc_parts[index:])
            if candidate_site in self.sites:
                deepmerge(overrides, self.sites[candidate_site])

        return overrides
