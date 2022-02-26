from __future__ import annotations

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

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
        self.scrapes = set()
        self.title_scrapes = set()
        self.failed_scrapes = set()

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
        self.system = BaseSystem.from_json(self.config, demo=False)
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
                # Ignore clones
                if machine.parent_name or machine.title in self.title_scrapes:
                    continue

                # Ignore BIOS
                if 'bios' in machine.name.lower():
                    print(f'[{machine.name}] Skipping BIOS')
                    continue

                # Scrape if:
                # * Configured for all
                # * Configured for missing and the machine is missing
                # * Configured for empty and the metadata is empty
                data = self.metadata.get(machine.title)
                is_missing = (data is None)
                is_empty = (not is_missing and not (data['genres'] or data['rating']))

                if self.refresh == RefreshConfig.ALL or (self.refresh == RefreshConfig.MISSING and is_missing) or (self.refresh == RefreshConfig.EMPTY and is_empty):
                    self.scrape_machine(machine)
                else:
                    print(f'[{machine.name}] Already scraped')

    # Scrape the given machine
    def scrape_machine(self, machine: Machine) -> None:
        # Track that we scraped the machine
        self.scrapes.add(machine.name)
        self.title_scrapes.add(machine.title)

        # Get the query parameters based on the largest file as this will
        # represent the underlying ROM file.  This works for all systems
        # *except* arcade which is okay because arcade has its own metadata
        # source that we don't have to scrape from.
        primary_rom = machine.primary_rom
        romnom = quote(primary_rom.name).replace('%28', '(').replace('%29',')')
        crc = primary_rom.crc.upper()

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
        print(f"romnom: {romnom}, crc: {crc}, primary_rom: {primary_rom.rom_name}")
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
            self.failed_scrapes.add(machine.name)
        else:
            print(f'[{machine.name}] Found')

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

            # Only add the metadata if:
            # * It succeeded
            # * Configured to override all machines or
            # * Configured to override just the machines scraped
            if name not in self.failed_scrapes and (self.override == OverrideConfig.ALL or name in self.scrapes):
                title = Machine.title_from(name)
                if title not in self.metadata:
                    self.metadata[title] = {'genres': [], 'rating': None}

                data = self.metadata[title]
                if genres_csv:
                    data['genres'] = re.split(', *', genres_csv)

                if rating:
                    data['rating'] = rating

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
