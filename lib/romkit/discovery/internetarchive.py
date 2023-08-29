from __future__ import annotations

from romkit.discovery import BaseDiscovery

import lxml.etree
from pathlib import Path
from urllib.parse import urlparse

class InternetArchiveDiscovery(BaseDiscovery):
    name = 'internetarchive'

    def list_paths(self, url: str) -> List[str]:
        # Download the file
        parsed_url = urlparse(url)
        archive_name = Path(parsed_url.path).name
        filename = f'{archive_name}_files.xml'
        self.update(f'{url}/{filename}', filename)

        # Extract paths
        doc = lxml.etree.iterparse(str(self.download_dir.joinpath(filename)), tag=('file'))
        paths = []
        for event, element in doc:
            paths.append(element.get('name'))

        return paths
