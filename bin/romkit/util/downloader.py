from romkit.auth import BaseAuth

import logging
import os
import requests
import shutil
import tempfile
from pathlib import Path
from urllib.parse import urlparse

class Downloader:
    _instance = None

    def __init__(self, auth=None):
        if auth:
            self.auth = BaseAuth.from_name(auth)()
        else:
            self.auth = None

    @classmethod
    def instance(cls):
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
            cls._instance.__init__()
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
            with tempfile.TemporaryDirectory() as tmp_dir:
                # Initially download to a temporary directory so we don't overwrite until
                # the download is completed successfully
                download_path = Path(os.path.join(tmp_dir, Path(destination_path).stem))

                with requests.get(source, headers=headers, cookies=cookies, stream=True) as response:
                    response.raise_for_status()

                    # Stream the writes to avoid too much memory consumption
                    with open(download_path, 'wb') as download_file:
                        for chunk in response.iter_content(chunk_size=(10 * 1024 * 1024)):
                            download_file.write(chunk)

                if download_path.stat().st_size > 0:
                    # Rename file to final destination
                    os.rename(download_path, destination_path)
                else:
                    raise requests.exceptions.HTTPError(response=response)
