from __future__ import annotations

from romkit.auth import BaseAuth

import logging
import requests
import shutil
import tempfile
from pathlib import Path, PurePath
from urllib.parse import urlparse

class Downloader:
    _instance = None

    def __init__(self, auth: str = None) -> None:
        self.auth = auth and BaseAuth.from_name(auth)

    @classmethod
    def instance(cls) -> Downloader:
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
            cls._instance.__init__()
        return cls._instance

    # Attempts to download from the given source unless either:
    # * It already exists in the destination
    # * The file is being force-refreshed
    def get(self, source: str, destination: Path, force: bool =False):
        if self.auth and self.auth.match(source):
            headers = self.auth.headers
            cookies = self.auth.cookies
        else:
            headers = {}
            cookies = {}

        source_uri = urlparse(source)

        # Ensure directory exists
        destination.parent.mkdir(parents=True, exist_ok=True)

        if source_uri.scheme == 'file':
            # Copy directly from the filesystem
            logging.info(f'Copying {source} to {destination}')
            shutil.copyfile(source_uri.path, destination)
        elif not destination.exists() or destination.stat().st_size == 0 or force:
            # Re-download the file
            logging.info(f'Downloading {source} to {destination}')
            with tempfile.TemporaryDirectory() as tmp_dir:
                # Initially download to a temporary directory so we don't overwrite until
                # the download is completed successfully
                download_path = Path(tmp_dir).joinpath(destination.name)

                with requests.get(source, headers=headers, cookies=cookies, stream=True) as response:
                    response.raise_for_status()

                    # Stream the writes to avoid too much memory consumption
                    with download_path.open('wb') as download_file:
                        for chunk in response.iter_content(chunk_size=(10 * 1024 * 1024)):
                            download_file.write(chunk)

                if download_path.stat().st_size > 0:
                    # Rename file to final destination
                    download_path.rename(destination)
                else:
                    raise requests.exceptions.HTTPError(response=response)
