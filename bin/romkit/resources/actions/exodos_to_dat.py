from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import lxml.etree
import tempfile
from pathlib import Path, PureWindowsPath

class ExodosToDat(BaseAction):
    name = 'exodos_to_dat'

    # Converts an exodos MS-DOS.xml file to a dat file readable by romkit
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        doc = lxml.etree.iterparse(str(source.path), tag=('Game'))

        with tempfile.TemporaryDirectory() as tmpdir:
            # Write initially to a temporary file in case there's a failure part-way through
            tmp_target = Path(tmpdir).joinpath('out.xml')

            with lxml.etree.xmlfile(str(tmp_target), encoding='utf-8') as file:
                file.write_declaration(standalone=True)
                file.write_doctype('<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD ROM Management Datafile//EN" "http://www.logiqx.com/Dats/datafile.dtd">')

                with file.element('datafile'):
                    for event, game in doc:
                        # Get actual name as it'll be downloaded from the source
                        application_path = game.find('ApplicationPath').text
                        if application_path:
                            path = PureWindowsPath(application_path)
                            name = path.stem
                            sourcefile = path.parent.stem

                            # Build element in target file
                            element = lxml.etree.Element('game', name=name, sourcefile=sourcefile)
                            
                            # Add description
                            description = lxml.etree.Element('description')
                            description.text = name
                            element.append(description)

                            # Add ROM
                            element.append(lxml.etree.Element('rom', name=f'{name}.zip'))

                            file.write(element, pretty_print=True)
                            element = None

                        # Release memory
                        game.clear()

            tmp_target.rename(target.path)
