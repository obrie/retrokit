from romkit.auth import BaseAuth

import configparser
from pathlib import Path
from urllib.parse import unquote

class InternetArchiveAuth(BaseAuth):
    CONFIG_FILE = f"{str(Path.home())}/.ia"
    ARCHIVE_ORG_DOMAIN = 'archive.org'

    name = 'internetarchive'

    def __init__(self) -> None:
        config = configparser.ConfigParser()
        config.read(self.CONFIG_FILE)

        self.user = config.get('cookies', 'logged-in-user', raw=True).split(';')[0]
        self.signature = config.get('cookies', 'logged-in-sig', raw=True).split(';')[0]

    def match(self, url: str) -> bool:
        return self.ARCHIVE_ORG_DOMAIN in url

    @property
    def cookies(self) -> dict:
        return {'logged-in-user': self.user, 'logged-in-sig': self.signature}
