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

        download_path = self.download_dir.joinpath(filename)

        # Extract paths
        try:
            doc = lxml.etree.iterparse(str(download_path), tag=('file'))
            paths = []
            for event, element in doc:
                paths.append(element.get('name'))
        except lxml.etree.Error as e:
            # Remove the invalid file so that we re-attempt it next time
            download_path.unlink(missing_ok=True)
            raise

        return paths
