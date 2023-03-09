from __future__ import annotations

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
            archive_name = Path(parsed_url.path).name
            filename = f'{archive_name}_files.xml'
            download_path = self.download_dir.joinpath(filename)
            self.download(f'{url}/{filename}', download_path)

            doc = lxml.etree.iterparse(str(download_path), tag=('file'))
            for event, element in doc:
                filepath = element.get('name')
                result = pattern.search(filepath)
                if result:
                    # Build the url
                    discovered_url = urljoin(f'{url}/', quote(filepath))

                    # Track either a machine-specific url or a general url
                    if 'machine' in result.groupdict():
                        self._mappings[result['machine']] = discovered_url
                    else:
                        self._mappings[None] = discovered_url

    def keys(self) -> Set[str]:
        return set(self._mappings.keys())

    def discover(self, context: dict) -> Dict[str, str]:
        values = [None]
        if 'machine' in context:
            values.append(context['machine'])

        if 'machine_alt_names' in context:
            values.extend(context['machine_alt_names'])

        for value in values:
            if value in self._mappings:
                return self._mappings[value]
