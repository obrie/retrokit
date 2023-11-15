from __future__ import annotations

from romkit.resources.adapters import BaseAdapter

import logging
import time
from urllib.request import urlretrieve

# Supports downloading from FTP sources
class FTPAdapter(BaseAdapter):
    schemes = ['ftp']

    def download(self, source: str, destination: Path, session: Session) -> None:
        attempts = 0

        while True:
            try:
                urlretrieve(source, str(destination))
                break
            except Exception as e:
                attempts += 1
                if attempts > session.retries:
                    raise e
                else:
                    logging.debug(f'Download error for {source} (attempt #{attempts}): {e}')
                    time.sleep(session.timeout)
