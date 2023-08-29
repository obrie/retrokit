from __future__ import annotations

from romkit.resources.actions.file_to_dat import FileToDat

import lxml.etree
import re
from pathlib import Path

class LibretroToDat(FileToDat):
    name = 'libretro_to_dat'

    # Converts an archive file listing to a dat file readable by romkit
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        lines = Path(source.path).read_text().split('\n')

        with self.create_dat(target) as file:
            # Build element in target file
            element = None

            for line in lines:
                line = line.strip()

                if line.startswith('game'):
                    # <game> START
                    element = lxml.etree.Element('game')
                elif element is not None:
                    if line.startswith('rom'):
                        # <rom> START / END
                        line = re.sub(r'^rom \((.+)\)$', '\g<1>', line).strip()
                        attrs = self.__find_attr_values(line)
                        element.append(lxml.etree.Element('rom', attrib=attrs))
                    elif line.startswith(')'):
                        # <game> END
                        file.write(element, pretty_print=True)
                        element = None
                    else:
                        # Add new attributes
                        attrs = self.__find_attr_values(line)
                        for attr, value in attrs.items():
                            if attr != 'name':
                                attr_element = lxml.etree.Element(attr)
                                attr_element.text = value
                                element.append(attr_element)
                            else:
                                element.attrib['name'] = value

    # Finds attribute name/value pairs on the given line
    def __find_attr_values(self, line: str) -> Dict[str, str]:
        attrs = {}

        while True:
            line = line.strip()
            result = re.search(r'^([^ ]+) ("[^"]+"|[^ ]+)', line)
            if result:
                line = line.replace(result[0], '')
                attrs[result[1]] = re.sub(r'^"|"$', '', result[2])
            else:
                break

        return attrs
