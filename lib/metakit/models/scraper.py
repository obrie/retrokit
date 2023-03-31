from __future__ import annotations

import configparser
import json
import hashlib
import logging
import lxml.etree
import os
import re
import shutil
import subprocess
import tempfile
from enum import Enum
from pathlib import Path
from urllib.parse import quote

class ScrapeType(Enum):
    # Only scrape machines that we haven't previously scraped
    NEW = 'new'

    # Only scrape machines that had just some data scraped successfully
    INCOMPLETE = 'incomplete'

    # Only scrape machines that were successfully looked up, but no data found
    MISSING = 'missing'

    # Scrape all machines
    ALL = 'all'

class Scraper:
    # Path to the skyscraper config on the filesystem
    SKYSCRAPER_CONFIG_PATH = Path(os.path.dirname(__file__)).joinpath('../config/skyscraper.ini')

    # Pattern used to detect scraping failures
    ERROR_PATTERN = r'API is currently closed|blacklisted|request limit has been reached|invalid / empty Json|Error was:'

    # Metadata attributes that the scraper can populate
    ATTRIBUTE_NAMES = {'genres', 'rating', 'players', 'year', 'publisher', 'developer', 'age_rating'}

    def __init__(self, system: BaseSystem) -> None:
        self.system = system
        self.dataset = {}

        # Take note of which sources we're scraping rom
        scraper_settings = system.config['scraper']
        self.scraper_sources = scraper_settings['sources']
        if 'args' in scraper_settings and '-p' in scraper_settings['args']:
            self.scraper_platform = scraper_settings['args'][scraper_settings['args'].index('-p') + 1]
        else:
            self.scraper_platform = self.system.name

        # Paths to be filled out when running
        self.scraper_base_path = Path(os.environ['RETROKIT_HOME']).joinpath('tmp/scraper')
        self.scraper_config_path = self.scraper_base_path.joinpath('skyscraper.ini')
        self.scraper_roms_path = self.scraper_base_path.joinpath(f'roms')
        self.scraper_system_cache_path = Path(os.environ['RETROKIT_HOME']).joinpath(f'cache/scraper/{self.system.name}')
        self.scraper_db_path = self.scraper_system_cache_path.joinpath('db.xml')

    @property
    def romkit(self) -> ROMKit:
        return self.system.romkit

    # Loads the scraper database and updates matching groups with metadata
    def update_metadata(self) -> None:
        self._load()

        for group in self.romkit.resolved_groups:
            if group in self.dataset:
                # Scraped machine found -- Go ahead and use it
                data_to_update = {key: value for key, value in self.dataset[group].items() if value is not None}
                self.system.database.update(group, data_to_update)

    # Loads metadata from the scraper database
    def _load(self) -> None:
        self.romkit.load()

        if not self.scraper_db_path.exists():
            return

        # Map quickids
        quickid_to_group = {}
        for group in self.romkit.resolved_groups:
            quickid_to_group[self._scraper_id(group)] = group

        # Load from the scraper database
        self.dataset.clear()
        doc = lxml.etree.iterparse(str(self.scraper_db_path), tag=('resource'))
        for event, element in doc:
            value = element.text
            if not value:
                continue

            # Look up the associated group name
            quickid = element.get('id')
            group = quickid_to_group.get(quickid)
            if not group:
                # Not a resolved group anymore -- ignore
                continue

            if group not in self.dataset:
                self.dataset[group] = {}

            # Update the metadata
            metadata = self.dataset[group]
            attribute_name = element.get('type')
            if attribute_name == 'genre':
                metadata['genres'] = re.split(', *', value)
            elif attribute_name == 'rating':
                metadata['rating'] = float(value)
            elif attribute_name == 'players':
                metadata['players'] = max([int(players) for players in value.replace('+', '').split('-')])
            elif attribute_name == 'releasedate':
                if value[0:4].isnumeric():
                    metadata['year'] = int(value[0:4])
                else:
                    metadata['year'] = None
            elif attribute_name == 'publisher':
                metadata['publisher'] = value
            elif attribute_name == 'developer':
                metadata['developer'] = value
            elif attribute_name == 'ages':
                metadata['age_rating'] = value

    # Generates the filename to use for the given group
    def _scraper_filename(self, group: str) -> str:
        return f'{group}.zip'

    # Generates the quickid used internally by skyscraper
    def _scraper_id(self, group: str) -> str:
        return hashlib.sha1(self._scraper_filename(group).encode()).hexdigest()

    # Start scraping for metadata associated with this system
    def scrape(self, scrape_type: ScrapeType = ScrapeType.NEW) -> None:
        # Ensure paths exist
        for path in [self.scraper_base_path, self.scraper_roms_path, self.scraper_system_cache_path]:
            if not path.exists():
                path.mkdir(parents=True, exist_ok=True)

        self._eval_skyscraper_config()
        self._load()

        # Start scraping
        try:
            self._scrape_groups(scrape_type)
        except KeyboardInterrupt:
            logging.error('Scraping interrupted.  Pulling whatever data we can.')

        # Remove unused data
        self.clean()

    # Evaluate the skyscraper config path by replacing environment variables
    # and storing the result on the filesystem
    def _eval_skyscraper_config(self) -> None:
        with self.SKYSCRAPER_CONFIG_PATH.open('r') as source_file:
            config = os.path.expandvars(source_file.read())

        # Write the new skyscraper config so it can be picked up by the tool
        with self.scraper_config_path.open('w') as target_file:
            target_file.write(config)

    # Scrape all games for the current system that we don't already have
    def _scrape_groups(self, scrape_type: ScrapeType) -> None:
        for group in sorted(self.romkit.resolved_groups):
            should_scrape = False
            if scrape_type == ScrapeType.ALL:
                should_scrape = True
            elif scrape_type == ScrapeType.NEW:
                should_scrape = (group not in self.dataset)
            elif scrape_type == ScrapeType.MISSING:
                should_scrape = (len(metadata) == 1 and 'title' in metadata)
            else:
                metadata = self.dataset.get(group, {})
                should_scrape = (self.ATTRIBUTE_NAMES.intersection(metadata.keys()) != self.ATTRIBUTE_NAMES)

            if should_scrape:
                self._scrape_group(group)

    # Scrape the given group
    def _scrape_group(self, group: str) -> None:
        machine = self.romkit.resolved_group_to_machine[group]

        # Get the query parameters based on the largest file as this will
        # represent the underlying ROM file.  This works for all systems
        # *except* arcade which is okay because arcade has its own metadata
        # source that we don't have to scrape from.
        primary_rom = machine.primary_rom
        if primary_rom and machine.romset.system.rom_id_type == 'crc':
            romnom = quote(primary_rom.name).replace('%28', '(').replace('%29',')')
            crc = primary_rom.crc.upper()
        elif machine.resource:
            romnom = machine.resource.target_path.path.name
            crc  = ''
        else:
            return

        # Create a fake file so we can actually invoke skyscraper
        rom_path = self.scraper_roms_path.joinpath(self._scraper_filename(group))
        rom_path.touch()

        # Run skyscraper against all of the configured scraping modules.
        # 
        # Note that this requires 2 requests each time, unfortunately.
        # We *could* use our own API key instead of going through skyscraper
        # and maybe we'll do that at some point.
        # 
        # For now, though, let skyscraper do the API integration work
        # instead of us.  Maybe we can get skyscraper to allow querying
        # without doing an upfront API request for the user's limits.
        for scraper_source in self.scraper_sources:
            scraper_args = ['-s', scraper_source]
            if scraper_source == 'screenscraper':
                scraper_args.extend(['--query', f'crc={crc}&romnom={romnom}'])

            output = self._exec_skyscraper(
                check=True,
                capture_output=True,
                args=[*scraper_args, str(rom_path)],
            )

            if 'found! :)' not in output:
                error_match = re.search(self.ERROR_PATTERN, output)
                if error_match:
                    # There was an error during lookup -- we're going to have to look this one
                    # up again another time.
                    logging.info(f'[{group}] Error - {machine.name} - {error_match.group()}')
                else:
                    logging.info(f'[{group}] Not found - {machine.name}')

                    # Add title to db.xml so we at least know that we successfully scraped
                    if self.scraper_db_path.exists():
                        doc = self._read_scraper_db()
                        title_resource = lxml.etree.Element('resource')
                        title_resource.attrib.update({
                            'id': self._scraper_id(group),
                            'type': 'title',
                            'source': 'user',
                            'timestamp': '0',
                        })
                        title_resource.text = machine.title
                        doc.getroot().append(title_resource)
                        self._save_scraper_db(doc)
            else:
                logging.info(f'[{group}] Found')
                break

        # Clean up
        rom_path.unlink()

    # Runs the Skyscraper command with the given arguments
    def _exec_skyscraper(self, check=False, capture_output=False, args: list = []) -> None:
        output = subprocess.run([
            '/opt/retropie/supplementary/skyscraper/Skyscraper',
            '-p', self.scraper_platform,
            '-c', str(self.scraper_config_path),
            '-d', str(self.scraper_system_cache_path),
            '-i', str(self.scraper_roms_path),
            *args,
        ], check=check, capture_output=capture_output)

        if capture_output:
            return output.stdout.decode()

    # Cleans the scrape data files
    def clean(self) -> None:
        if not self.scraper_db_path.exists():
            return

        self._load()

        quickid_to_group = {}
        for group in self.romkit.resolved_groups:
            quickid_to_group[self._scraper_id(group)] = group

        removed_quickids = set()

        doc = self._read_scraper_db()
        for element in doc.iter('resource'):
            quickid = element.get('id')
            source = element.get('source')
            group = quickid_to_group.get(quickid)

            if group:
                if source == 'user' and self.dataset[group]:
                    # The group has found metadata, so we can get rid of the
                    # user source used for tracking purposes
                    logging.info(f'Removing tracker for {quickid}')
                    element.getparent().remove(element)
                else:
                    # Clean up the associated attributes
                    element.attrib['timestamp'] = '0'
            else:
                # Group name may have changed or doesn't exist anymore
                removed_quickids.add(quickid)
                element.getparent().remove(element)

        for quickid in removed_quickids:
            logging.info(f'Removed unknown quickid {quickid}')

        # Rewrite the file
        self._save_scraper_db(doc)

    # Migrates the metadata from one group name to another
    def migrate(self, from_group: str, to_group: str) -> None:
        from_quickid = self._scraper_id(from_group)
        to_quickid = self._scraper_id(to_group)
        migrated = False

        doc = self._read_scraper_db()
        for element in doc.iter('resource'):
            quickid = element.get('id')
            data_type = element.get('type')
            if quickid == from_quickid:
                migrated = True
                element.attrib['id'] = to_quickid

        if migrated:
            logging.info(f'[{from_group}] [scraper] Migrated metadata')

        self._save_scraper_db(doc)

    def _read_scraper_db(self):
        parser = lxml.etree.XMLParser(remove_blank_text=True)
        return lxml.etree.parse(str(self.scraper_db_path), parser)

    def _save_scraper_db(self, doc):
        lxml.etree.indent(doc, '    ')
        doc.write(str(self.scraper_db_path), encoding='utf-8', xml_declaration=True)
