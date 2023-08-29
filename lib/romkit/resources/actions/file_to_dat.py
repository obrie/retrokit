from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import lxml.etree
import tempfile
from contextlib import contextmanager
from pathlib import Path

# Provides a standard interface for converting a file to a standard DAT format
class FileToDat(BaseAction):
    @contextmanager
    def create_dat(self, target: ResourcePath) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            # Write initially to a temporary file in case there's a failure part-way through
            tmp_target = Path(tmpdir).joinpath('out.xml')

            with lxml.etree.xmlfile(str(tmp_target), encoding='utf-8') as file:
                file.write_declaration(standalone=True)
                file.write_doctype('<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD ROM Management Datafile//EN" "http://www.logiqx.com/Dats/datafile.dtd">')

                with file.element('datafile'):
                    yield file

            tmp_target.rename(target.path)
