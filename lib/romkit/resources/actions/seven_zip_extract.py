from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import re
import shutil
import subprocess
import tempfile
from pathlib import Path

class SevenZipExtract(BaseAction):
    name = '7z_extract'

    # Extracts files from the source to the target directory
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmpdir = Path(tmpdir)

            if self.config.get('file'):
                # List files
                file_details = subprocess.run(['7z', 'l', '-ba', '-slt', source.path], check=True, capture_output=True).stdout.decode().splitlines()
                filenames = []
                for file_detail in file_details:
                    parts = file_detail.split(' = ')
                    key = parts[0]
                    value = ''.join(parts[1:])
                    if key == 'Path':
                        filenames.append(value)

                # Find the file in the zip based on the given pattern
                pattern = re.compile(self.config['file'])
                filename = next(filter(lambda filename: pattern.match(filename), filenames))

                # Extract to temp dir
                subprocess.run(['7z', 'e', '-y', source.path, f'-o{tmpdir}', filename], check=True, stdout=subprocess.DEVNULL)

                # Move to final destination
                shutil.move(str(tmpdir.joinpath(Path(filename).name)), str(target.path))
            else:
                # Extract all to temp dir
                subprocess.run(['7z', 'x', '-y', source.path, f'-o{tmpdir}'], check=True, stdout=subprocess.DEVNULL)

                if self.config.get('include_parent') == False:
                    # Move children to final destination
                    target.path.mkdir(parents=True)
                    for child_path in tmpdir.glob('*/*'):
                        shutil.move(str(child_path), str(target.path))
                else:
                    # Move to final destination
                    shutil.move(str(tmpdir), str(target.path))

        # Remove the source as it's no longer needed
        if self.config.get('delete_source') != False:
            source.path.unlink()
