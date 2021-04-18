from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import lxml.etree
from pathlib import PureWindowsPath

class ExodosToDat(BaseAction):
    name = 'exodos_to_dat'

    # Converts an exodos MS-DOS.xml file to a dat file readable by romkit
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        doc = lxml.etree.iterparse(str(source.path), tag=('Game'))
        _, root = next(doc)

        with lxml.etree.xmlfile(str(target.path), encoding='utf-8') as file:
            file.write_declaration(standalone=True)
            file.write_doctype('<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD ROM Management Datafile//EN" "http://www.logiqx.com/Dats/datafile.dtd">')

            with file.element('datafile'):
                for event, game in doc:
                    # Get actual name as it'll be downloaded from the source
                    application_path = game.find('ApplicationPath').text
                    if application_path:
                        name = PureWindowsPath(application_path).stem

                        # Build element in target file
                        element = lxml.etree.Element('game', name=name)
                        
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

        # Release memory
        root.clear()
