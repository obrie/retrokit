from __future__ import annotations

from romkit.discovery import BaseDiscovery
from romkit.util.dict_utils import slice_only

import ftplib
from pathlib import Path
from urllib.parse import urlparse
import re

class FTPDiscovery(BaseDiscovery):
    name = 'ftp'

    def __init__(self, *args, max_depth: int = -1, **kwargs):
        super().__init__(*args, **kwargs)

        self.max_depth = max_depth

    # Build additional arguments for constructing this class
    @classmethod
    def parse_extra_args(cls, json: dict) -> dict:
        return slice_only(json, ['max_depth'])

    # Lists files available on the remote FTP server
    def list_paths(self, url: str) -> List[str]:
        # Download the file listing
        parsed_url = urlparse(url)
        filename = f"{parsed_url.path[1:].replace('/', '_') or 'root'}.depth-{self.max_depth}.lst"
        self.update(url, filename, do_update=self._download_filelist)

        # Read what we've cached
        return self.download_dir.joinpath(filename).read_text().split('\n')

    # Downloads the list of files available at the given url (a recursive list)
    def _download_filelist(self, url: str, download_path: Path) -> List[str]:
        parsed_url = urlparse(url)

        # List remote paths
        with ftplib.FTP(host=parsed_url.hostname, user=parsed_url.username, passwd=parsed_url.password) as ftp:
            paths = self._remote_list_paths_in_dir(ftp, Path(parsed_url.path or '/'))

        # Write to the download path
        with download_path.open('w') as f:
            f.write('\n'.join(paths))

    # Lists the paths available in the remote FTP service at the given directory
    #
    # The depth indicates how much recursion we've done so far in order to make sure
    # we don't exceed max_depth.
    def _remote_list_paths_in_dir(self, ftp: ftplib.FTP, base_dir: Path, remote_dir: Path = None, depth: int = 0) -> List[str]:
        if remote_dir is None:
            remote_dir = base_dir

        paths = []

        # List the lines with chmod details so we know which results are files and
        # which are directories
        lines = []
        ftp.dir(str(remote_dir), lambda line: lines.append(line))

        for line in lines:
            # Split the output so we can identify chmod details and filenames
            file_attrs = re.split(r' +', line, maxsplit=8)
            if len(file_attrs) < 8:
                # Note a valid filename listing -- likely the "total" line that gets returned
                continue

            filename = file_attrs[-1]
            path = remote_dir.joinpath(filename)
            dir_modifier = file_attrs[0][0]

            paths.append(str(path.relative_to(base_dir)))

            # Recursively list
            if dir_modifier == 'd' and (self.max_depth == -1 or depth < self.max_depth):
                paths.extend(self._remote_list_paths_in_dir(ftp, base_dir, path, depth + 1))

        return paths
