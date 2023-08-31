from __future__ import annotations

from romkit.resources.adapters import BaseAdapter

import logging
import shutil
from urllib.parse import unquote, urlparse

# Supports downloading from the local filesystems
class FileAdapter(BaseAdapter):
    schemes = ['file']

    def force(self, source: str, destination: Path) -> bool:
        source_uri = urlparse(source)
        return unquote(source_uri.path) != str(destination)

    def download(self, source: str, destination: Path) -> None:
        if self.force(source, destination):
            logging.debug(f'Copying {source} to {destination}')
            source_uri = urlparse(source)
            shutil.copyfile(unquote(source_uri.path), destination)
