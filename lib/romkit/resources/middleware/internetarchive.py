from romkit.resources.middleware import BaseMiddleware

import logging
import re
import subprocess
from http import cookies
from pathlib import Path

class InternetArchiveAuthMiddleware(BaseMiddleware):
    name = 'internetarchive_auth'

    BASE_URL = 'archive.org/download/'
    PUBLIC_AUTH_MATCH = re.compile(r'(files\.xml|meta\.sqlite|meta\.xml|reviews\.xml)')

    def __init__(self) -> None:
        self.cookies = None

    def match(self, url: str) -> bool:
        # Skip non-archive.org download URLs
        if self.BASE_URL not in url:
            return False

        # Allow certain unauthenticated URLs
        if self.PUBLIC_AUTH_MATCH.search(url):
            return False

        return True

    @property
    def overrides(self) -> dict:
        if self.cookies is None:
            self._load_ia_config()

        return {'cookies': self.cookies}

    # Look up authentication data
    def _load_ia_config(self) -> None:
        try:
            cookie_data = subprocess.run(['ia', 'configure', '-c'], check=True, capture_output=True).stdout.decode()

            cookie = cookies.SimpleCookie()
            cookie.load(cookie_data)

            self.cookies = {
                'logged-in-user': cookie['logged-in-user'].value,
                'logged-in-sig': cookie['logged-in-sig'].value,
            }
        except Exception as e:
            logging.debug(f'Failed to load internetarchive cookies: {e}')

            # Ensure we only try once by setting cookies
            self.cookies = {}
