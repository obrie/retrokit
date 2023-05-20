#!/usr/bin/python3

import logging
import os
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

from metakit.models.scraper import ScrapeType
from metakit.systems import BaseSystem

import json
from argparse import ArgumentParser
from signal import signal, SIGPIPE, SIG_DFL

class MetaKit:
    def __init__(self,
        action: str,
        config_file: str,
        log_level: str = 'INFO',
    ) -> None:
        self.action = action

        # Load configuration (and expand env vars)
        with open(config_file) as f:
            self.config = json.loads(os.path.expandvars(f.read()))

        # Set up logger
        logging.basicConfig(level=getattr(logging, log_level), format='%(asctime)s - %(message)s', stream=sys.stdout)

        # Build system
        self.system = BaseSystem.from_json(self.config)

    def run(self) -> None:
        getattr(MetaKit, self.action)(self)

    # Validate the content of the system's database
    def validate(self) -> bool:
        errors = self.system.validate()
        if errors:
            for key in sorted(errors.keys()):
                logging.warning(f'[{key}] Error: {", ".join(errors[key])}')
            sys.exit(1)

    # Validates that machines are mapped properly to names in each romset's discovery
    # data.
    def validate_discovery(self):
        self.system.validate_discovery()

    # Vacuums unneded data from the system's database
    def vacuum(self) -> None:
        self.system.vacuum()
        self.system.save()

    # Format the system's database
    def format(self) -> None:
        self.system.save()

    # Runs the full update process for a single system:
    # * Update DAT files
    # * Re-organize groups
    # * Re-cache externally sourced metadata
    # * Update the metadata based on external sources
    # * Scrape metadata from a scraper website
    def update(self) -> None:
        self.update_dats()
        self.update_groups()
        self.vacuum()
        self.system.reload()
        self.recache_external_data()
        self.scrape()
        self.update_metadata()

    # Bring all romset dats up-to-date
    def update_dats(self) -> None:
        self.system.update_dats()

    # Migrates groups to their current names as defined by the system's DAT
    # files and the priority settings defined in the metakit configuraiton
    def update_groups(self) -> None:
        self.system.update_groups()
        self.system.save()

    # Requests that the system download any external data it doesn't already
    # have cached.
    def cache_external_data(self, *args, **kwargs) -> None:
        self.system.cache_external_data(*args, **kwargs)

    # Forces any external data used by the system to be re-downloaded.  This
    # is useful if any changes have been made and we want to use the latest
    # content.
    def recache_external_data(self) -> None:
        self.cache_external_data(refresh=True)

    # Scrapes for metadata from external services
    def scrape(self, *args, **kwargs) -> None:
        self.system.scrape(*args, **kwargs)

    # Forces machines that have incomplete scrape metadata to be refreshed from the source
    def scrape_incomplete(self) -> None:
        self.scrape(ScrapeType.INCOMPLETE)

    # Forces machines that have were never found in the scraper sources
    def scrape_missing(self) -> None:
        self.scrape(ScrapeType.MISSING)

    # Forces all scraped metadata to be refreshed from the source
    def rescrape(self) -> None:
        self.scrape(ScrapeType.ALL)

    # Update the content of the database based on internal/external data
    def update_metadata(self) -> None:
        self.system.update_metadata()
        self.system.save()

def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='action', help='Action to perform', choices=[
        'validate',
        'validate_discovery',
        'vacuum',
        'format',
        'update',
        'update_dats',
        'update_groups',
        'cache_external_data',
        'recache_external_data',
        'scrape_incomplete',
        'scrape_missing',
        'rescrape',
        'update_metadata',
    ])
    parser.add_argument(dest='config_file', help='JSON file containing the configuration')
    parser.add_argument('--log-level', dest='log_level', help='Log level', default='INFO', choices=['DEBUG', 'INFO', 'WARN', 'ERROR'])
    args = parser.parse_args()
    MetaKit(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
