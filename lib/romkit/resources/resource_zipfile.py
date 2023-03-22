from romkit.models.file import File
from romkit.resources.resource_path import ResourcePath

import contextlib
import logging
import os
import subprocess
import tempfile
import zipfile
from pathlib import Path
from typing import Optional, Set

class ResourceZipFile(ResourcePath):
    extensions = ['zip']
    can_list_files = True

    def list_files(self) -> Set[File]:
        files = set()

        if self.exists():
            try:
                with zipfile.ZipFile(self.path, 'r') as zip_ref:
                    for zip_info in zip_ref.infolist():
                        name = zip_info.filename
                        size = zip_info.compress_size
                        crc = "%0.8X" % zip_info.CRC
                        files.add(self.build_file(name, size, crc))
            except zipfile.BadZipFile:
                # Ignore
                pass

        return files

    # Re-archives the file using TorrentZip for consistency with other services
    def clean(self, expected_files: Optional[Set[File]] = None) -> None:
        if not self.exists():
            return

        with zipfile.ZipFile(self.path, 'r') as zip_ref:
            zip_file_count = len(zip_ref.infolist())

        if zip_file_count:
            logging.debug(f"Torrentzip'ing {self.path} {expected_files}")

            # Run trrntzip in its own directory due to the log files it creates (with no control)
            with tempfile.TemporaryDirectory() as tmpdir:
                with self._pushd(tmpdir):
                    subprocess.run(['trrntzip', self.path], stdout=subprocess.DEVNULL, check=True)

            # Remove files we don't need
            if expected_files:
                for file in (self.list_files() - expected_files):
                    logging.warn(f'Removing unexpected file {file.name} from {self.path}')
                    subprocess.run(['zip', '-d', self.path, file.name], check=True)

    @contextlib.contextmanager
    def _pushd(self, new_dir: str) -> None:
        previous_dir = os.getcwd()
        os.chdir(new_dir)
        try:
            yield
        finally:
            os.chdir(previous_dir)
