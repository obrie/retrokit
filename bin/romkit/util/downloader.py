from romkit.auth import BaseAuth

import logging
import os
import requests
import shutil
from pathlib import Path
from urllib.parse import urlparse

class Downloader:
    def __init__(self, auth=None):
        if auth:
            self.auth = BaseAuth.from_name(auth)()
        else:
            self.auth = None

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
        return cls._instance

    # Attempts to download from the given source unless either:
    # * It already exists in the destination
    # * The file is being force-refreshed
    def get(self, source, destination, force=False):
        if self.auth and self.auth.match(source):
            headers = self.auth.headers
            cookies = self.auth.cookies
        else:
            headers = {}
            cookies = {}

        source_uri = urlparse(source)
        destination_path = Path(destination)

        if source_uri.scheme == 'file':
            # Copy directly from the filesystem
            logging.info(f'Copying {source} to {destination}')
            shutil.copyfile(source_uri.path, destination)
        elif not destination_path.exists() or destination_path.stat().st_size == 0 or force:
            # Ensure directory exists
            Path(os.path.dirname(destination_path)).mkdir(parents=True, exist_ok=True)

            # Re-download the file
            logging.info(f'Downloading {source} to {destination}')
            with requests.get(source, headers=headers, cookies=cookies, stream=True) as response:
                response.raise_for_status()

                with open(f'{destination_path}.tmp', 'wb') as destination_file:
                    for chunk in response.iter_content(chunk_size=(10 * 1024 * 1024)):
                        destination_file.write(chunk)

            # Rename file to final destination
            os.rename(f'{destination_path}.tmp', destination_path)
