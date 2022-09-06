from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import glob
import subprocess
import tempfile
import zipfile
from pathlib import Path

class ZipToChd(BaseAction):
    name = 'zip_to_chd'

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        with zipfile.ZipFile(source.path, 'r') as source_zip, tempfile.TemporaryDirectory() as extract_dir:
            extract_dir = Path(extract_dir)

            source_zip.extractall(path=extract_dir)
            cue_file = next(extract_dir.rglob('*.cue'))

            # Run chdman
            tmp_target = extract_dir.joinpath('out.chd')
            subprocess.run(['chdman', 'createcd', '-f', '-i', cue_file, '-o', tmp_target], check=True)
            tmp_target.rename(target.path)

        source.delete()
