from romkit.discovery import BaseDiscovery
from romkit.util import Downloader

import lxml.etree
import tempfile
from pathlib import Path
from urllib.parse import quote, urljoin, urlparse

class NoIntroDiscovery(BaseDiscovery):
    name = 'nointro'

    def load(self) -> None:
        filename = Path(urlparse(self.metadata_url).path).name
        self.metadata_filepath = self.download_dir.joinpath(filename)
        
        self.download(self.metadata_url, self.metadata_filepath)

    def discover(self, pattern: str) -> str:
        doc = lxml.etree.iterparse(str(self.metadata_filepath), tag=('file'))

        for event, element in doc:
            filepath = element.get('name')
            if pattern.search(filepath):
                return urljoin(f'{self.base_url}/', quote(filepath))
