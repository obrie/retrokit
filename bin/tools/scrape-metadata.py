from __future__ import annotations

import logging
import lxml.etree
import os
import re
import sys
import time
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from romkit.systems import BaseSystem

import configparser
import json
import subprocess
import tempfile
from argparse import ArgumentParser
from signal import signal, SIGPIPE, SIG_DFL
from urllib.parse import quote, urlparse

class Scraper:
    def __init__(self,
        config_file: str,
    ) -> None:
        self.config_file = config_file

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

        # Get target metadata path
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

        with tempfile.TemporaryDirectory() as tmpdir:
            self.tmpdir = Path(tmpdir)

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

    # Scrape all games for the current system that we don't already have
    def scrape(self) -> None:
        # Path to store the files skyscraper will be looking at
        roms_dir = self.tmpdir.joinpath(f'roms')
        roms_dir.mkdir()

        for romset in self.system.iter_romsets():
            for (machine, xml) in romset.iter_machines():
                # Ignore clones
                if machine.parent_name:
                    continue

                # Make sure we haven't already scraped this machine
                if machine.name in self.metadata:
                    print(f'[{machine.name}] Already scraped')
                    continue

                self.scrape_machine(machine)

    # Scrape the given machine
    def scrape_machine(self, machine: Machine) -> None:
        # Get the query parameters based on the largest file as this will
        # represent the underlying ROM file.  This works for all systems
        # *except* arcade which is okay because arcade has its own metadata
        # source that we don't have to scrape from.
        largest_file = sorted(machine.non_merged_roms, key=lambda file: file.size)[-1]
        romnom = quote(largest_file.name).replace('%28', '(').replace('%29',')')
        crc = largest_file.crc.upper()

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
        subprocess.run([
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
        ], check=True)

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

            # Only write the metadata if we were able to scrape some genres.
            # Otherwise, it may be indicating of a failure to scrape or failure
            # to find the game -- so we want to allow ourselves to retry again
            # in the future by excluding it from the target.
            if genres_csv:
                genres = re.split(', *', genres_csv)
                self.metadata[name] = {'rating': rating, 'genres': genres}

            element.clear()

        # Save it to the configured metadata path
        with open(self.metadata_path, 'w') as file:
            json.dump(self.metadata, file,
                indent=4,
                sort_keys=True,
            )

def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='config_file', help='JSON file containing the configuration')
    args = parser.parse_args()
    Scraper(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
