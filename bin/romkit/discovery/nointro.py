from romkit.discovery import BaseDiscovery
from romkit.util import Downloader

import lxml.etree
import tempfile
from urllib.parse import quote, urljoin

class NoIntroDiscovery(BaseDiscovery):
    name = 'nointro'

    def load(self):
        self.metadata_filepath = f'{tempfile.gettempdir()}/{self.romset.name}-files.xml'
        self.download(urljoin(f'{self.base_url}/', self.metadata_url_path), self.metadata_filepath)

    def discover(self, pattern):
        doc = lxml.etree.iterparse(self.metadata_filepath, tag=('file'))

        for event, element in doc:
            filepath = element.get('name')
            if pattern.search(filepath):
                return urljoin(f'{self.base_url}/', quote(filepath))
