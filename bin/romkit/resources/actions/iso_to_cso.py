from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import subprocess
import tempfile
from pathlib import Path

class IsoToCso(BaseAction):
    name = 'iso_to_cso'

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs):
        with tempfile.TemporaryDirectory() as tmp_dir:
            # Run maxcso
            tmp_target = Path(tmp_dir).joinpath('out.cso')
            subprocess.run(['maxcso', '--block=16384', source.path, '-o', tmp_target], check=True)
            tmp_target.rename(target.path)

        source.delete()
