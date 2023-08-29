from __future__ import annotations

from romkit.resources.actions.file_to_dat import FileToDat

import lxml.etree
import re
from pathlib import Path

class ArchiveToDat(FileToDat):
    name = 'archive_to_dat'

    # Converts an archive file listing to a dat file readable by romkit
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        doc = lxml.etree.iterparse(str(source.path), tag=('file'))
        pattern = re.compile(self.config.get('match', '.*'))

        with self.create_dat(target) as file:
            for event, archive_file in doc:
                # Get actual name as it'll be downloaded from the source
                archive_filename = archive_file.get('name')

                if pattern.search(archive_filename):
                    archive_name = Path(archive_filename).stem

                    # Build element in target file
                    element = lxml.etree.Element('game', name=archive_name)

                    # Add description
                    description_element = lxml.etree.Element('description')
                    description_element.text = archive_name
                    element.append(description_element)

                    # Add rom
                    rom_element = lxml.etree.Element('rom', attrib={
                        'name': archive_filename,
                    })

                    archive_size = archive_file.find('size')
                    if archive_size is not None:
                        rom_element.attrib['size'] = archive_size.text

                    archive_md5 = archive_file.find('md5')
                    if archive_md5 is not None:
                        rom_element.attrib['md5'] = archive_md5.text

                    archive_crc32 = archive_file.find('crc32')
                    if archive_crc32 is not None:
                        rom_element.attrib['crc'] = archive_crc32.text

                    archive_sha1 = archive_file.find('sha1')
                    if archive_sha1 is not None:
                        rom_element.attrib['sha1'] = archive_sha1.text

                    element.append(rom_element)
                    file.write(element, pretty_print=True)

                # Release memory
                archive_file.clear()
