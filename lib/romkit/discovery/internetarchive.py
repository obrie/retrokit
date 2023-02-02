from romkit.discovery import BaseDiscovery

import logging
import lxml.etree
import re
import tempfile
from pathlib import Path
from urllib.parse import quote, urljoin, urlparse, urlunparse
from typing import Dict

class InternetArchiveDiscovery(BaseDiscovery):
    name = 'internetarchive'

    def load(self) -> None:
        pattern = re.compile(self.match)
        self._mappings = {}

        for url in self.urls:
            parsed_url = urlparse(url)
            if not parsed_url.scheme:
                logging.debug(f'Unable to run discovery for {parsed_url}')
                continue

            # Download the file
            filename = Path(parsed_url.path).name
            download_path = self.download_dir.joinpath(filename)
            self.download(url, download_path)

            # Define the base url
            base_url_parts = list(parsed_url)
            base_url_parts[2] = str(Path(parsed_url.path).parent)
            base_url = urlunparse(base_url_parts)

            doc = lxml.etree.iterparse(str(download_path), tag=('file'))
            for event, element in doc:
                filepath = element.get('name')
                result = pattern.search(filepath)
                if result:
                    # Build the url
                    discovered_url = urljoin(f'{base_url}/', quote(filepath))

                    # Track either a machine-specific url or a general url
                    if 'machine' in result.groupdict():
                        self._mappings[result['machine']] = discovered_url
                    else:
                        self._mappings[None] = discovered_url

    def discover(self, context: dict) -> Dict[str, str]:
        return self._mappings.get(None) or ('machine' in context and self._mappings.get(context['machine'])) or ('machine_alt_name' in context and self._mappings.get(context['machine_alt_name']))
