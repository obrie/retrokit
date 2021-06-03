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
            extract_dir = Path(extract_dir)

            source_zip.extractall(path=extract_dir)
            iso_file = next(extract_dir.rglob('*.iso'))

            # Run maxcso
            tmp_target = extract_dir.joinpath('out.cso')
            subprocess.run(['maxcso', '--block=16384', iso_file, '-o', tmp_target], check=True)
            tmp_target.rename(target.path)

        source.delete()
