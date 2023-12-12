from __future__ import annotations

import logging

from metakit.models.database import Database
from metakit.models.romkit import ROMKit
from metakit.models.scraper import Scraper
from metakit.models.manual_finder import ManualFinder

class BaseSystem:
    name = 'base'

    def __init__(self, config: dict) -> None:
        self.name = config['system']
        self.config = config
        self.romkit = ROMKit(config)
        self.database = Database(self.romkit, config)
        self.scraper = Scraper(self)
        self.manual_finder = ManualFinder(self)

    # Looks up the system from the given name
    @classmethod
    def from_json(cls, json: dict) -> None:
        name = json['system']

        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls(json)

        return cls(json)

    # Identify the groups that are expected to be in the database file
    @property
    def target_groups(self) -> Set[str]:
        pass

    # Forces romkit data to be reloaded
    def reload(self) -> None:
        self.romkit.load(force=True)

    # Run several validation checks on the content of the database
    def validate(self) -> ValidationResults:
        return self.database.validate(target_groups=self.target_groups)

    # Run several validation checks on the content of the database
    def validate_discovery(self) -> None:
        attribute = self.database.attribute('alternates')
        if not attribute.valid_discovered_names:
            return

        self.romkit.load()
        for group in self.romkit.resolved_groups:
            for machine in self.romkit.find_machines_by_group(group):
                name_candidates = set(machine.alt_names + [machine.name])
                if not name_candidates.intersection(attribute.valid_discovered_names):
                    print(f'[{machine.name}] Failed to discover')

    # Format and re-save the database (helps create a consistent structure)
    def save(self) -> None:
        self.database.save()

    # Update dats from their sources
    def update_dats(self) -> None:
        for romset in self.romkit.romsets:
            dat = romset.dat
            if not dat:
                continue

            dat.download(force=True)
            dat.install(force=True)

            # Rewrite newlines
            with dat.target_path.path.open('rb') as f:
                content = f.read()
            content = content.replace(b'\r\n', b'\n')
            with dat.target_path.path.open('wb') as f:
                f.write(content)

    # Update groups based on the current romsets defined for the system
    def update_groups(self) -> None:
        migration = self.database.build_migration_plan(target_groups=self.target_groups)
        for from_key in sorted(migration.keys()):
            to_key = migration[from_key]

            if to_key is None:
                logging.info(f'[{from_key}] Removed')
                self.database.delete(from_key)
            elif from_key == to_key:
                logging.info(f'[{to_key}] Added')
                self.database.update(to_key, {})
            else:
                logging.info(f'[{from_key}] Renamed: {to_key}')
                self.database.migrate(from_key, to_key)
                self.scraper.migrate(from_key, to_key)

    # Removes any outdated data we can determine is no longer needed
    def vacuum(self) -> None:
        self.romkit.load()
        self.database.clean()
        self.scraper.clean()

    # Caches any external data used by the system
    def cache_external_data(self, refresh: bool = False) -> None:
        pass

    # Updates the metadata for this system based on data from a scraping service
    def scrape(self, *args, **kwargs) -> None:
        self.scraper.scrape(*args, **kwargs)

    # Searches for manuals for this system
    def find_manuals(self, *args, **kwargs) -> None:
        self.manual_finder.run(*args, **kwargs)

    # Snapshots source manual websites for this system
    def snapshot_manuals(self, *args, **kwargs) -> None:
        self.manual_finder.snapshot(*args, **kwargs)

    # Updates the metadata for games associated with this system
    def update_metadata(self) -> None:
        self.scraper.update_metadata()
        self.database.update_metadata_from_romkit()
