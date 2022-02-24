from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path

class ZipNibconv(BaseAction):
    name = 'zip_nibconv'

    def install(self, source: ResourcePath, target: ResourcePath, files: Set[File]) -> None:
        source_extension = self.config['source_extension']
        target_extension = self.config['target_extension']

        with zipfile.ZipFile(source.path, 'r') as source_zip, tempfile.TemporaryDirectory() as staging_dir:
            # Extract all files
            extract_dir = staging_dir.join('extract')
            source_zip.extract_all(extract_dir)

            # Convert .nib files
            for source_file in extract_dir.glob(f'*.{source_extension}'):
                converted_file = source_file.parent.join(f'{source_file.stem}.{target_extension}')
                subprocess.run(['nibconv', str(source_file), str(converted_file)], check=True)

                # Remove the .nib so it's not included in the new zip
                source_file.unlink()

            # Create a new zip file and copy it to the target
            staging_path = staging_dir.join('out.zip')
            shutil.make_archive(staging_dir.join('out'), 'zip', extract_dir)
            staging_path.rename(target.path)
