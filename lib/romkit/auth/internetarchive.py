from romkit.auth import BaseAuth

import re
import subprocess
from http import cookies
from pathlib import Path

class InternetArchiveAuth(BaseAuth):
    name = 'internetarchive'

    BASE_URL = 'archive.org/download/'
    PUBLIC_AUTH_MATCH = re.compile(r'(files\.xml|meta\.sqlite|meta\.xml|reviews\.xml)')

    def __init__(self) -> None:
        self.user = None
        self.signature = None

    def match(self, url: str) -> bool:
        # Skip non-archive.org download URLs
        if self.BASE_URL not in url:
            return False

        # Allow certain unauthenticated URLs
        if self.PUBLIC_AUTH_MATCH.search(url):
            return False

        return True

    @property
    def cookies(self) -> dict:
        if not self.user and not self.signature:
            self._load_ia_config()

        return {'logged-in-user': self.user, 'logged-in-sig': self.signature}

    # Look up authentication data
    def _load_ia_config(self) -> None:
        cookie_data = subprocess.run(['ia', 'configure', '-c'], check=True, capture_output=True).stdout.decode()

        cookie = cookies.SimpleCookie()
        cookie.load(cookie_data)

        self.user = cookie['logged-in-user'].value
        self.signature = cookie['logged-in-sig'].value
