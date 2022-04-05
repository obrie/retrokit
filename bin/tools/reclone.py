#!/usr/bin/python3

import argparse
import json
import lxml.etree
import re

from pathlib import Path
from typing import List, Optional

# Generates parent/clone configurations generally based on the rules layed out
# here: https://forum.no-intro.org/viewtopic.php?p=9503&sid=7c1efa5d868e8dd0d0836f033691563a#p9503
# 
# This helps create parent/clone relationships for Redump that match No-Intro
class Recloner:
    TITLE_REGEX = re.compile(r'^[^\(]+')
    DISC_REGEX = re.compile(r'\(Disc [0-9A-Z]+\)')
    PROTO_REGEX = re.compile(r'\((Proto|Beta|Alpha|Demo|Unl|Alt|Pirate)')
    VERSION_REGEX = re.compile(r'\((Version|Rev|v|Ver.)')
    NUMBER_REGEX = re.compile(r'[0-9]+')
    FLAG_REGEX = re.compile(r'\(([^\)]+)\)')
    FLAG_CHARS = re.compile(r'[^A-Za-z0-9 ]')
    DISC_CODE_FLAG_REGEX = re.compile(r'^([0-9]+)[A-Z]+$')
    NORMALIZED_TITLE_REGEX = re.compile(r'[^a-z0-9\+&\.]+')
    PRIMARY_COUNTRIES = ['Europe', 'USA', 'Japan']
    PRIMARY_LANGUAGES = {'En', 'English'}
    OTHER_FLAGS = ['Made in EU', 'Made in Japan']

    def __init__(self,
        clones_path: str,
        dat_path: str,
        metadata_path: Optional[str] = None,
        dry_run: bool = False,
    ) -> None:
        self.clones_path = clones_path
        self.dat_path = dat_path
        self.metadata_path = metadata_path
        self.dry_run = dry_run

    # Gets the title without the disc number
    def get_title(self, name: str) -> str:
        return self.TITLE_REGEX.search(name).group().strip()

    # Generates the title + disc number from the given name.  This excludes
    # country, revision, etc.
    def get_disc_title(self, name: str) -> str:
        title = self.get_title(name)

        disc_match = self.DISC_REGEX.search(name)
        if disc_match:
            title = f'{title} {disc_match.group().replace("0", "")}'

        return title

    # Gets the disc code number (e.g. 1 if flag is 1M)
    def get_disc_code_number(self, flag: str) -> int:
        disc_code_match = self.DISC_CODE_FLAG_REGEX.search(flag)
        if disc_code_match:
            return int(disc_code_match.group(1))

    # Normalizes the title to account for differences in case / symbols
    def normalize(self, title: str) -> str:
        return self.NORMALIZED_TITLE_REGEX.sub('', title.lower())

    # Generates the sort keys for the given ROM name.  The keys are sorted by
    # highest priority => lowest priority.
    def sort_keys(self, name: str) -> List[str]:
        title = self.get_title(name)

        keys = []
        flag_groups = self.FLAG_REGEX.findall(name)
        flags_str = ','.join(flag_groups)
        flags = re.sub(r'\s*,\s*', ',', flags_str).split(',')
        flags = map(lambda flag: re.sub(self.FLAG_CHARS, '', flag), flags)
        flags = set(flags)

        # Priority non-prototypes
        if self.PROTO_REGEX.search(name):
            keys.append(1)
        else:
            keys.append(0)

        # Prioritize World releases
        if 'World' in flags:
            keys.append(0)
        else:
            keys.append(1)

        # Prioritize:
        # 1. Multiple primary countires
        # 2. Single primary country
        matching_countries = list(filter(lambda c: c in flags, self.PRIMARY_COUNTRIES))
        if len(matching_countries) > 1:
            keys.append(-31)
        elif len(matching_countries) == 1:
            country = matching_countries[0]
            matching_flag_group = next(filter(lambda flag_group: country in flag_group, flag_groups))
            num_countries = len(matching_flag_group.split(','))

            keys.append(self.PRIMARY_COUNTRIES.index(country) * 31 - num_countries)
        else:
            keys.append(len(self.PRIMARY_COUNTRIES) * 31)

        # Prioritize English-based titles
        if len(self.PRIMARY_LANGUAGES & flags) > 0:
            keys.append(0)
        else:
            keys.append(1)

        # Prioritize titles without revisions
        if self.VERSION_REGEX.search(name):
            keys.append(1)
        else:
            keys.append(0)

        # Sort by additional flags
        matching_flag = next(filter(lambda f: f in flags, self.OTHER_FLAGS), None)
        if matching_flag:
            keys.append(self.OTHER_FLAGS.index(matching_flag))
        else:
            keys.append(len(self.OTHER_FLAGS))

        # Sort by title length
        keys.append(len(title))

        # Sort by lowest number detected in the title (e.g. year, version)
        number_match = self.NUMBER_REGEX.search(title)
        if number_match:
            keys.append(int(number_match.group()))
        else:
            keys.append(-1)

        # Sort by earlier disc code (e.g. 1M, 1S)
        disc_codes = sorted(filter(None, map(self.get_disc_code_number, flags)))
        if disc_codes:
            keys.append(disc_codes[0])
        else:
            keys.append(-1)

        # Sort by name length
        keys.append(len(name))

        return keys

    def run(self) -> None:
        with open(self.clones_path, 'r') as f:
            old_clones = json.load(f)

        disc_title_to_group = {}
        groups = {}

        # Track existing custom configurations
        for parent_name, clone_disc_titles in old_clones.items():
            parent_disc_title = self.get_disc_title(parent_name)
            disc_title_to_group[self.normalize(parent_disc_title)] = parent_disc_title

            for clone_disc_title in clone_disc_titles:
                disc_title_to_group[self.normalize(clone_disc_title)] = parent_disc_title

        # Group together related ROMs
        doc = lxml.etree.iterparse(self.dat_path, tag=('game', 'machine'))
        for event, element in doc:
            name = element.get('name')
            disc_title = self.get_disc_title(name)
            normalized_disc_title = self.normalize(disc_title)

            group_id = disc_title_to_group.get(normalized_disc_title, normalized_disc_title)
            if group_id not in groups:
                groups[group_id] = []
            groups[group_id].append(name)

            element.clear()

        new_clones = {}

        for group_names in groups.values():
            if len(group_names) > 1:
                # Sort alphabetically
                group_names.sort()

                # Sort by our own rules
                group_names.sort(key=self.sort_keys)

                # Parent will be first
                parent_name = group_names[0]
                parent_disc_title = self.get_disc_title(parent_name)

                # Only keep titles that don't match the parent
                clone_disc_titles = set(map(self.get_disc_title, group_names))
                clone_disc_titles.remove(parent_disc_title)

                # Track the new clone configuration
                new_clones[parent_name] = list(clone_disc_titles)
                new_clones[parent_name].sort()

        # Wirte out the new clone config
        clones_json = json.dumps(new_clones, indent=4, sort_keys=True)
        print(clones_json)

        if not self.dry_run:
            with open(self.clones_path, 'w') as f:
                f.write(clones_json)

            # Update metadata mappings
            if self.metadata_path:
                # Map clone disc title => parent disc title
                clone_to_parent = {}
                for parent_name, clone_disc_titles in new_clones.items():
                    parent_title = self.get_title(parent_name)
                    clone_to_parent[parent_title] = parent_title
                    for clone_disc_title in clone_disc_titles:
                        clone_to_parent[self.get_title(clone_disc_title)] = parent_title

                with open(self.metadata_path, 'r') as f:
                    old_metadata = json.load(f)

                # Build new metadata based on new parents
                new_metadata = {}
                for old_parent_title, metadata in old_metadata.items():
                    if old_parent_title in clone_to_parent:
                        new_parent_title = clone_to_parent[old_parent_title]
                        new_metadata[new_parent_title] = metadata
                    else:
                        new_metadata[old_parent_title] = metadata

                metadata_json = json.dumps(new_metadata, indent=4, sort_keys=True)
                with open(self.metadata_path, 'w') as f:
                    f.write(metadata_json)


def main() -> None:
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument(dest='clones_path', help='JSON file containing the current clone data')
    parser.add_argument(dest='dat_path', help='DAT file for the system')
    parser.add_argument('--metadata-path', dest='metadata_path', help='Scraper metadata file for the system')
    parser.add_argument('--dry-run', dest='dry_run', action='store_true')
    args = parser.parse_args()
    Recloner(**vars(args)).run()

if __name__ == '__main__':
    main()
