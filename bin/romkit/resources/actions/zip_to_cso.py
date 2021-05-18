from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import glob
import subprocess
import tempfile
import zipfile
from pathlib import Path

class ZipToCso(BaseAction):
    name = 'zip_to_cso'

    def install(self, source, target, **kwargs):
        with zipfile.ZipFile(source.path, 'r') as source_zip, tempfile.TemporaryDirectory() as extract_dir:
            source_zip.extractall(path=extract_dir)
            iso_file = next(Path(extract_dir).rglob('*.iso'))

            # Run maxcso
            subprocess.run(['maxcso', '--block=16384', '--format=cso2', iso_file, '-o', target.path], check=True)

        source.delete()
