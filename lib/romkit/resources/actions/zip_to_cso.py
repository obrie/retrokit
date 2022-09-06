from __future__ import annotations

from romkit.resources.actions.iso_to_cso import IsoToCso
from romkit.resources.resource_path import ResourcePath

import glob
import subprocess
import tempfile
import zipfile
from pathlib import Path

class ZipToCso(IsoToCso):
    name = 'zip_to_cso'

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        with zipfile.ZipFile(source.path, 'r') as source_zip, tempfile.TemporaryDirectory() as extract_dir:
            extract_dir = Path(extract_dir)

            source_zip.extractall(path=extract_dir)
            iso_file = next(extract_dir.rglob('*.iso'))

            super().install(ResourcePath(source.resource, iso_file), target, **kwargs)

        source.delete()
