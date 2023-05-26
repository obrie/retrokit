from __future__ import annotations

from romkit.resources.actions.base import BaseAction
from romkit.util.zip_file import MutableZipFile

import shutil
import subprocess
import tempfile
import zipfile
from pathlib import Path
from typing import Set

class ZipMerge(BaseAction):
    name = 'zip_merge'

    def install(self, source: ResourcePath, target: ResourcePath, files: Set[File]) -> None:
        source_files = source.list_files()
        source_files_by_id = {file.id: file for file in source_files}
        existing_files = target.list_files()
        existing_files_by_name = {file.name: file for file in existing_files}

        # Open target zip for appending new files
        with MutableZipFile(target.path, 'a') as target_zip:
            for file in files:
                existing_file = existing_files_by_name.get(file.name)
                if existing_file:
                    if file.id == existing_file.id:
                        # File already exists with same CRC; skip
                        continue
                    else:
                        # File exists with a different CRC; remove it
                        logging.debug(f'Removing conflicting file {existing_file.name} from {target.path}')
                        target_zip.remove(existing_file.name)

                # Write ROM from source
                source_file = source_files_by_id[file.id]
                with zipfile.ZipFile(source.path, 'r') as source_zip, tempfile.TemporaryDirectory() as extract_dir:
                    extract_filepath = Path(extract_dir).joinpath('file')

                    # Extract the file to the filesystem (avoiding read it all in memory)
                    with source_zip.open(source_file.name) as source_fp, extract_filepath.open('wb') as extract_fp:
                        shutil.copyfileobj(source_fp, extract_fp)

                    # Write to target zip
                    target_zip.write(extract_filepath, file.name)
