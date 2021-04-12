from romkit.resources.actions.base import BaseAction

import glob
import subprocess
import tempfile
import zipfile

class ZipToChd(BaseAction):
    name = 'zip_to_chd'

    def run(self, source, target, **kwargs):
        with zipfile.ZipFile(source.path, 'r') as source_zip, tempfile.TemporaryDirectory() as extract_dir:
            source_zip.extractall(path=extract_dir)
            cue_file = glob.glob(f'{extract_dir}/*.cue')[0]

            # Run chdman
            subprocess.check_call(['chdman', 'createcd', '-f', '-i', cue_file, '-o', target.path])

        source.delete()
