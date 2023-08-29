from __future__ import annotations

from romkit.resources.actions.file_to_dat import FileToDat

import lxml.etree
import re
import tempfile
from pathlib import Path

# Converts Retroplay DAT files to retrokit-compatible DAT files with No-Intro naming
# conventions
class RetroplayToDat(FileToDat):
    name = 'retroplay_to_dat'

    # Map country abbrevation to country name
    COUNTRY_TRANSLATIONS = {
        'NTSC': 'USA',
        'Cz': 'Czech',
        'De': 'Germany',
        'Dk': 'Denmark',
        'Es': 'Spain',
        'Fi': 'Finland',
        'Fr': 'France',
        'Gr': 'Greece',
        'It': 'Italy',
        'Nl': 'Netherlands',
        'Pl': 'Poland',
        'Se': 'Sweden',
    }
    COUNTRY_DEFAULT = 'Europe'

    # Flags to exclude from the name
    EXCLUDE_FLAGS_PATTERN = re.compile(r'v[0-9]|^[0-9]{4}')

    # Pattern for determining if the game is a demo (so we can move it to a flag)
    DEMO_PATTERN = re.compile(r' (Demos?($| .*$))')

    # Pattern for determining if the game contains data disks (so we can move it to a flag)
    DATA_DISK_PATTERN = re.compile(r' ?& ?(Data Disk.*$)')

    # Pattern for matching (and removing) the whdload version
    VERSION_PATTERN = re.compile(r'_v([0-9]+\.[0-9]+)')

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        doc = lxml.etree.iterparse(str(source.path), tag=('machine'))
        all_renames = self.config.get('renames', {})
        renames = {match_name: title for match_name, title in all_renames.items() if match_name[0] != '/'}
        regex_renames = {re.compile(match_name[1:]): title for match_name, title in all_renames.items() if match_name[0] == '/'}

        with self.create_dat(target) as file:
            for event, game_dir in doc:
                for game in game_dir.findall('rom'):
                    game_filename = game.get('name')
                    game_basename = Path(game_filename).stem

                    filtered_flags = []

                    game_short_name = game_basename[0:game_basename.index('_')]

                    # Build candidate title name
                    game_title = game_short_name
                    game_title = re.sub(r'^([^()]+)\)', r'\1', game_title)
                    game_title = re.sub(r'([A-Z\d]+)([A-Z][a-z])', r'\1 \2', game_title)
                    game_title = re.sub(r'([a-z])([A-Z\d])', r'\1 \2', game_title)
                    game_title = re.sub(r'([a-z0-9])([&])([A-Z])', r'\1 \2 \3', game_title)
                    game_title = game_title.replace('Disk 0', 'Disk ')

                    # Move "Demo" out of title
                    demo_match = self.DEMO_PATTERN.search(game_title)
                    if demo_match:
                        game_title = game_title.replace(demo_match.group(), '')
                        filtered_flags.append(demo_match.group(1))

                    # Move "Data Disk" out of title
                    data_disk_match = self.DATA_DISK_PATTERN.search(game_title)
                    if data_disk_match:
                        game_title = game_title.replace(data_disk_match.group(), '')
                        filtered_flags.append(data_disk_match.group(1))

                    # Build relevant flags
                    all_flags = game_basename[(game_basename.index('_') + 1):].split('_')
                    country_flag = self.COUNTRY_DEFAULT
                    for flag in all_flags:
                        if flag in self.COUNTRY_TRANSLATIONS:
                            country_flag = self.COUNTRY_TRANSLATIONS[flag]
                            continue
                        elif self.EXCLUDE_FLAGS_PATTERN.match(flag):
                            continue

                        filtered_flags.append(flag)

                    # Check for override
                    if game_short_name in renames:
                        game_title = renames[game_short_name]
                    else:
                        for regex_rename, rename_title in regex_renames.items():
                            if regex_rename.match(game_basename):
                                game_title = rename_title
                                break

                    game_name = f'{game_title} ({country_flag})'
                    if filtered_flags:
                        game_name = f'{game_name} ({") (".join(filtered_flags)})'

                    # Build element in target file
                    element = lxml.etree.Element('game', name=game_name)
                    
                    # Add description
                    description_element = lxml.etree.Element('description')
                    description_element.text = game_name
                    element.append(description_element)

                    # Non-versioned rom
                    game_unversioned_filename = self.VERSION_PATTERN.sub('', game_filename)

                    # Add rom
                    rom_element = lxml.etree.Element('rom', attrib={
                        'name': game_unversioned_filename,
                        'size': game.get('size'),
                        'crc': game.get('crc'),
                        'md5': game.get('md5'),
                        'sha1': game.get('sha1'),
                    })

                    element.append(rom_element)
                    file.write(element, pretty_print=True)

                # Release memory
                game.clear()
