from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import lxml.etree
import re
import tempfile
from pathlib import Path

class ArchiveToDat(BaseAction):
    name = 'archive_to_dat'

    # Converts an archive file listing to a dat file readable by romkit
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        doc = lxml.etree.iterparse(str(source.path), tag=('file'))
        pattern = re.compile(self.config.get('match', '.*'))

        with tempfile.TemporaryDirectory() as tmpdir:
            # Write initially to a temporary file in case there's a failure part-way through
            tmp_target = Path(tmpdir).joinpath('out.xml')

            with lxml.etree.xmlfile(str(tmp_target), encoding='utf-8') as file:
                file.write_declaration(standalone=True)
                file.write_doctype('<!DOCTYPE datafile PUBLIC "-//Logiqx//DTD ROM Management Datafile//EN" "http://www.logiqx.com/Dats/datafile.dtd">')

                with file.element('datafile'):
                    for event, archive_file in doc:
                        # Get actual name as it'll be downloaded from the source
                        filename = archive_file.get('name')

                        if pattern.search(filename):
                            name = Path(filename).stem

                            # Build element in target file
                            element = lxml.etree.Element('game', name=name)

                            # Add description
                            description = lxml.etree.Element('description')
                            description.text = name
                            element.append(description)

                            # Add rom
                            rom = lxml.etree.Element('rom')
                            rom.attrib['name'] = filename

                            size_tag = archive_file.find('size')
                            if size_tag is not None:
                                rom.attrib['size'] = size_tag.text

                            md5_tag = archive_file.find('md5')
                            if size_tag is not None:
                                rom.attrib['md5'] = md5_tag.text

                            crc32_tag = archive_file.find('crc32')
                            if crc32_tag is not None:
                                rom.attrib['crc'] = crc32_tag.text

                            sha1_tag = archive_file.find('sha1')
                            if sha1_tag is not None:
                                rom.attrib['sha1'] = sha1_tag.text

                            element.append(rom)

                            file.write(element, pretty_print=True)
                            element = None

                        # Release memory
                        archive_file.clear()

            tmp_target.rename(target.path)
