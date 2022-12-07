from __future__ import annotations

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent.parent.joinpath('lib')))

from romkit.models.machine import Machine
from romkit.systems import BaseSystem

import argparse
import configparser
import json
import logging
import lxml.etree
import os
import re
import shutil
import subprocess
import tempfile
import time
from enum import Enum
from signal import signal, SIGPIPE, SIG_DFL
from typing import List
from urllib.parse import quote, urlparse

class RefreshConfig(Enum):
    # Only refresh machines that are missing from the genre list
    MISSING = 'missing'

    # Only refresh machines that have empty genres
    EMPTY = 'empty'

    # Only refresh machines that have missing data (genres, players, or rating)
    INCOMPLETE = 'incomplete'

    # Refresh all machines
    ALL = 'all'


class OverrideConfig(Enum):
    SCRAPED = 'scraped'
    ALL = 'all'


class Scraper:
    # Pattern used to detect scraping failures
    ERROR_PATTERN = r'API is currently closed|blacklisted|request limit has been reached|invalid / empty Json|Error was:'

    def __init__(self,
        config_file: str,
        refresh: RefreshConfig = RefreshConfig.MISSING,
        override: OverrideConfig = OverrideConfig.SCRAPED,
    ) -> None:
        self.config_file = config_file
        self.refresh = refresh
        self.override = override
        self.scrapes_found = set()
        self.scrapes_missed = set()
        self.group_titles = {}

        with open(self.config_file) as file:
            self.config = json.loads(os.path.expandvars(file.read()))

    def run(self) -> None:
        # Check that we have a scraping config
        if not 'scraper' in self.config:
            print(f'No scraper configured for {self.config["system"]}')
            return

        # Check that we're supposed to scrape metadata
        if 'metadata' not in self.config or 'scraper' not in self.config['metadata']:
            print(f'No metadata file configured for {self.config["system"]}')
            return

        # Build the system that we're scraping
        self.system = BaseSystem.from_json(self.config)
        self.scraper_sources = self.config['scraper']['sources']

        # Load existing metadata
        target_uri = self.config['metadata']['scraper']['source']
        self.metadata_path = Path(urlparse(target_uri).path)
        if self.metadata_path.exists() and self.metadata_path.stat().st_size > 0:
            # Find what we've already scraped so we don't do it again
            with open(self.metadata_path, 'r') as file:
                self.metadata = json.loads(file.read())
        else:
            self.metadata = {}

        # Copy the skyscraper config so we can explicitly disable videos
        scraper_config = configparser.ConfigParser()
        scraper_config.optionxform = str
        scraper_config.read('/opt/retropie/configs/all/skyscraper/config.ini')
        scraper_config['main']['videos'] = '"false"'

        self.tmpdir = Path(tempfile.gettempdir()).joinpath(self.system.name, 'scraper')
        if not self.tmpdir.exists():
            self.tmpdir.mkdir(parents=True)

        # Write the modified skyscraper config
        self.scraper_config_path = self.tmpdir.joinpath('skyscraper.ini')
        with open(self.scraper_config_path, 'w') as file:
            scraper_config.write(file, space_around_delimiters=False)

        # Start scraping
        try:
            self.scrape()
        except KeyboardInterrupt:
            print('Scraping interrupted.  Pulling whatever data we can.')

        # Generate output
        self.build_gamelist()
        self.output_metadata()

        # Clean up
        self.scraper_config_path.unlink()

    # Scrape all games for the current system that we don't already have
    def scrape(self) -> None:
        # Path to store the files skyscraper will be looking at
        roms_dir = self.tmpdir.joinpath(f'roms')
        if not roms_dir.exists():
            roms_dir.mkdir()

        for romset in self.system.iter_romsets():
            for machine in romset.iter_machines():
                # Set external emulator metadata
                self.system.metadata_set.update(machine)
                if not self.system.filter_set.allow(machine):
                    continue

                group_title = machine.parent_title or machine.title
                self.group_titles[machine.name] = group_title

                # Ignore BIOS
                if 'bios' in machine.name.lower():
                    print(f'[{machine.name}] Skipping BIOS')
                    continue

                # Skip if we're already:
                # * Successfully scraped the group or
                # * Attempted to scrape the specific machine (different clones may have matches)
                if group_title in self.scrapes_found or machine.name in (self.scrapes_found | self.scrapes_missed):
                    continue

                # Scrape if:
                # * Configured for all
                # * Configured for missing and the metadata is missing
                # * Configured for empty and the metadata is empty
                # * Configured for incomplete and the metadata is incomplete
                data = self.metadata.get(group_title)
                is_missing = (data is None)
                is_empty = (is_missing or not (data.get('genres') or data.get('rating') or data.get('players')))
                is_incomplete = (is_empty or not (data.get('genres') and data.get('rating') and data.get('players')))

                if self.refresh == RefreshConfig.ALL or (self.refresh == RefreshConfig.MISSING and is_missing) or (self.refresh == RefreshConfig.EMPTY and is_empty) or (self.refresh == RefreshConfig.INCOMPLETE and is_incomplete):
                    self.scrape_machine(machine)
                else:
                    print(f'[{machine.name}] Already scraped')

    # Scrape the given machine
    def scrape_machine(self, machine: Machine) -> None:
        # Get the query parameters based on the largest file as this will
        # represent the underlying ROM file.  This works for all systems
        # *except* arcade which is okay because arcade has its own metadata
        # source that we don't have to scrape from.
        primary_rom = machine.primary_rom
        if primary_rom:
            romnom = quote(primary_rom.name).replace('%28', '(').replace('%29',')')
            crc = primary_rom.crc.upper()
        else:
            romnom = machine.resource.target_path.path.name
            crc = ''

        # Create a fake file so we can actually invoke skyscraper
        rom_path = self.tmpdir.joinpath(f'roms').joinpath(f'{machine.name}.zip')
        rom_path.touch()

        # Run skyscraper against the screenscraper scraping module
        # 
        # Note that this requires 2 requests each time, unfortunately.
        # We *could* use our own API key instead of going through skyscraper
        # and maybe we'll do that at some point.
        # 
        # For now, though, let skyscraper do the API integration work
        # instead of us.  Maybe we can get skyscraper to allow querying
        # without doing an upfront API request for the user's limits.
        output = subprocess.run([
            '/opt/retropie/supplementary/skyscraper/Skyscraper',
            '-p', self.system.name,
            '-s', 'screenscraper',
            '-c', self.scraper_config_path,
            '-d', self.tmpdir,
            '-g', self.tmpdir,
            '-i', self.tmpdir.joinpath(f'roms'),
            '--verbosity', '3',
            '--flags', 'nocovers,nomarquees,noscreenshots,nowheels',
            '--query', f'crc={crc}&romnom={romnom}',
            rom_path,
        ], check=True, capture_output=True).stdout.decode()

        if 'found! :)' not in output and re.search(self.ERROR_PATTERN, output):
            print(f'[{machine.name}] Not found')

            # Only track the miss for this machine's title -- we can still re-attempt
            # the parent title if it's different
            self.scrapes_missed.add(machine.name)
            self.scrapes_missed.add(machine.title)
        else:
            print(f'[{machine.name}] Found')

            # Track the match for both this machine's title and its parent since there's
            # no need to re-scrape the parent
            self.scrapes_found.add(machine.name)
            self.scrapes_found.add(machine.title)
            if machine.parent_title:
                self.scrapes_found.add(machine.parent_title)

    # Build an emulationstation gamelist.xml that we can parse
    def build_gamelist(self) -> None:
        # We are explicitly not checking the exit code because if there are no
        # new games to scrape, then skyscraper will return a non-zero exit code
        subprocess.run([
            '/opt/retropie/supplementary/skyscraper/Skyscraper',
            '-p', self.system.name,
            '-c', self.scraper_config_path,
            '-d', self.tmpdir,
            '-g', self.tmpdir,
            '-i', self.tmpdir.joinpath(f'roms'),
            '--verbosity', '3',
        ])

    # Parse the gamelist and output the metadata in JSON
    def output_metadata(self) -> None:
        gamelist_path = self.tmpdir.joinpath('gamelist.xml')
        if not gamelist_path.exists():
            print('No new games to merge')
            return

        # Merge the metadata from the gamelist with the existing
        # data
        doc = lxml.etree.iterparse(str(gamelist_path), tag=('game'))
        for event, element in doc:
            name = Path(element.find('path').text).stem
            rating = element.find('rating').text
            genres_csv = element.find('genre').text
            players = element.find('players').text

            # Only add the metadata if:
            # * It succeeded
            # * Configured to override all machines or
            # * Configured to override just the machines scraped
            if name not in self.scrapes_missed and (self.override == OverrideConfig.ALL or name in self.scrapes_found):
                group_title = self.group_titles[name]
                if group_title not in self.metadata:
                    self.metadata[group_title] = {'genres': [], 'rating': None, 'players': None}

                data = self.metadata[group_title]
                if genres_csv:
                    data['genres'] = re.split(', *', genres_csv)

                if rating:
                    data['rating'] = float(rating)

                if players:
                    data['players'] = int(players)

            element.clear()

        # Save it to the configured metadata path
        with open(self.metadata_path, 'w') as file:
            json.dump(self.metadata, file,
                indent=4,
                sort_keys=True,
            )

def main() -> None:
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument(dest='config_file', help='JSON file containing the configuration')
    parser.add_argument('--refresh', dest='refresh', type=RefreshConfig, choices=list(RefreshConfig))
    parser.add_argument('--override', dest='override', type=OverrideConfig, choices=list(OverrideConfig))
    args = parser.parse_args()
    Scraper(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
