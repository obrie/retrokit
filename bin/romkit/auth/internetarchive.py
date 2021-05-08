from romkit.auth import BaseAuth

import subprocess
from http import cookies
from pathlib import Path
from urllib.parse import unquote

class InternetArchiveAuth(BaseAuth):
    ARCHIVE_ORG_DOMAIN = 'archive.org'

    name = 'internetarchive'

    def __init__(self) -> None:
        cookie_data = subprocess.run(['ia', 'configure', '-c'], check=True, capture_output=True).stdout.decode()

        cookie = cookies.SimpleCookie()
        cookie.load(cookie_data)

        self.user = cookie['logged-in-user'].value
        self.signature = cookie['logged-in-sig'].value

    def match(self, url: str) -> bool:
        return self.ARCHIVE_ORG_DOMAIN in url

    @property
    def cookies(self) -> dict:
        return {'logged-in-user': self.user, 'logged-in-sig': self.signature}
