from romkit.formats import BaseFormat

import contextlib
import logging
import os
import subprocess
import tempfile
from pathlib import Path

class Zip2CHDFormat(BaseFormat):
    name = 'zip2chd'

    # Looks up the ROMs that have been installed locally for the given machine
    def find_local_roms(self, machine):
        pass

    # Merges ROMs from the source machine to the given target machine
    def merge(self, source, target, roms):
        pass

    # Removes a ROM from a machine
    def remove(self, machine, rom):
        pass

    # Re-archives the file using TorrentZip for consistency with other services
    def finalize(self, machine):
        # chdman createcd -i <game.cue> -o <game.chd>
        pass
