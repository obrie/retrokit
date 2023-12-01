from __future__ import annotations

from romkit.resources.actions.file_to_dat import FileToDat

import lxml.etree
from pathlib import PureWindowsPath

class ExodosToDat(FileToDat):
    name = 'exodos_to_dat'

    # Converts an exodos MS-DOS.xml file to a dat file readable by romkit
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        doc = lxml.etree.iterparse(str(source.path), tag=('Game'))

        with self.create_dat(target) as file:
            for event, game in doc:
                # Get actual name as it'll be downloaded from the source
                application_path = game.find('ApplicationPath').text
                if application_path and application_path.startswith('eXo\\'):
                    path = PureWindowsPath(application_path)
                    name = path.stem
                    sourcefile = path.parent.stem

                    # Build element in target file
                    element = lxml.etree.Element('game', name=name, sourcefile=sourcefile)

                    # Add description
                    description_element = lxml.etree.Element('description')
                    description_element.text = name
                    element.append(description_element)

                    # Add Year
                    game_release_date = game.find('ReleaseDate')
                    if game_release_date is not None:
                        year_element = lxml.etree.Element('year')
                        year_element.text = game_release_date.text[0:4]
                        element.append(year_element)

                    # Add Manufacturer
                    game_developer = game.find('Developer')
                    if game_developer is not None:
                        manufacturer_element = lxml.etree.Element('manufacturer')
                        manufacturer_element.text = game_developer.text
                        element.append(manufacturer_element)

                    file.write(element, pretty_print=True)

                # Release memory
                game.clear()
