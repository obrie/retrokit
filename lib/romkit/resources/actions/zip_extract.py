from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import re
import shutil
import zipfile
from pathlib import Path

class ZipExtract(BaseAction):
    name = 'zip_extract'

    # Extracts files from the source to the target directory
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        with zipfile.ZipFile(source.path, 'r') as source_zip:
            if self.config.get('file'):
                # Find the file in the zip based on the given pattern
                pattern = re.compile(self.config['file'])
                file = next(filter(lambda file: pattern.match(file.name), source.list_files()))

                # Extract to the target
                with source_zip.open(file.name) as source_file, open(target.path, 'wb') as target_file:
                    shutil.copyfileobj(source_file, target_file)
            else:
                if self.config.get('include_parent') == False:
                    # Extract without the parent directory
                    for zip_info in source_zip.infolist():
                        root_parent = Path(zip_info.filename).parts[0]
                        zip_info.filename = zip_info.filename.replace(root_parent, '.', 1)
                        source_zip.extract(zip_info, target.path)
                else:
                    # Extract all files to directory
                    source_zip.extractall(path=target.path)

        # Remove the source as it's no longer needed
        if self.config.get('delete_source') != False:
            source.path.unlink()
