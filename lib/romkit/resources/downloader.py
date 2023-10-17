from __future__ import annotations

from romkit.auth import BaseAuth
from romkit.resources.adapters import BaseAdapter
from romkit.util.dict_utils import slice_only

import logging
import requests
import tempfile
from pathlib import Path
from urllib.parse import urlparse

# Provides requests-like functionality for downloading from different URI schemes
class Downloader:
    _instance = None

    def __init__(self,
        auth: BaseAuth = None,
        # Maximum number of concurrent chunks to download at once
        max_concurrency: int = 5,
        # File size after which the file will be split into multiple parts
        part_threshold: int = 10 * 1024 * 1024,
        # The size of parts that are downloaded in each thread
        part_size: int = 1 * 1024 * 1024,
        # Timeout *after* connection when no data is received
        timeout: int = 300,
        # Timeout of initial connection
        connect_timeout: int = 15,
        # Number of times to re-attempt a download
        retries: int = 3,
        # Backoff factor to apply between attempts
        backoff_factor: float = 2.0,
    ) -> None:
        self.auth = auth
        self.max_concurrency = max_concurrency
        self.part_threshold = part_threshold
        self.part_size = part_size
        self.timeout = timeout
        self.connect_timeout = connect_timeout
        self.retries = retries
        self.backoff_factor = backoff_factor
        self.adapters = {}

        # Build default mapping of adapters for handling different URI schemes
        for adapter in BaseAdapter.__subclasses__():
            adapter_instance = adapter(self)
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
        if 'auth' in json:
            auth = BaseAuth.from_json(json['auth'])
        else:
            auth = None

        return cls(auth=auth, **slice_only(json, [
            'max_concurrency',
            'part_threshold',
            'part_size',
            'timeout',
            'connect_timeout',
            'retries',
            'backoff_factor',
        ]), **kwargs)

    # Adds support for processing the given URI scheme with an adapter
    def mount(self, scheme: str, adapter: BaseAdapter) -> None:
        self.adapters[scheme] = adapter

    # Builds a new downloader configured for the given authentication
    def with_auth(self, auth: str) -> Downloader:
        return Downloader(
            auth=auth,
            max_concurrency=self.max_concurrency,
            part_threshold=self.part_threshold,
            part_size=self.part_size,
            timeout=self.timeout,
            connect_timeout=self.connect_timeout,
            retries=self.retries,
            backoff_factor=self.backoff_factor,
        )

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

                adapter.download(source, download_path)

                if download_path.exists() and download_path.stat().st_size > 0:
                    # Rename file to final destination
                    download_path.rename(destination)
                else:
                    download_path.unlink(missing_ok=True)
                    raise requests.exceptions.HTTPError()
