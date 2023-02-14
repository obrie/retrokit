from __future__ import annotations

import configparser
import os
import re

from romkit.resources.resource import ResourceTemplate

# Provides a unified interface for defining arcade metadata based on
# external sources
class ExternalData:
    MAME_ARCHIVE_RESOURCE = ResourceTemplate.from_json({
        'source': 'https://archive.org/download/mame-support/mame-support_files.xml',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/mame-support.xml',
    })

    # The name of the attribute we're updated
    attribute = None

    # The ResourceTemplate used for the external data being processed
    resource_template = None

    # The pattern to search for when looking up the data in the mame-support
    # archive.  If set to None, then we assume the external resource doesn't
    # need a version rendered in its template.
    version_pattern = None

    # Updates the given database with data loaded from the external resource
    def update(self, database: Database) -> None:
        self._load()
        self.update_attribute(database, self.attribute)

    # Updates the given attribute in the database
    def update_attribute(self, database: Database, attribute: str) -> None:
        romkit = database.romkit
        updated_names = set()

        for group in romkit.resolved_groups:
            # Update group
            updated_names.add(group)
            group_value = self.get_value(group, attribute, database)
            if group_value is not None:
                database.update(group, {attribute: group_value})

            # Update clones
            machines = romkit.find_machines_by_group(group)
            for machine in machines:
                if machine.name in updated_names:
                    continue

                updated_names.add(machine.name)

                # Add if clone value is different, otherwise delete
                clone_value = self.get_value(machine.name, attribute, database)
                if clone_value is not None:
                    if clone_value != group_value and self.allow_clone_overrides:
                        database.update(machine.name, {'group': group, attribute: clone_value})
                    else:
                        database.delete_attribute(machine.name, attribute)

    # Loads the data from the external resource.  By default, this assumes
    # that the resources is in an INI format as used in most ProgrettoSnaps
    # database files.
    # 
    # Format:
    # * Section: value for the metadata
    # * Key: name of the machine
    def _load(self) -> None:
        resource = self.download()

        self.values = {}
        ini_data = resource.target_path.path.read_text()
        config = configparser.ConfigParser(allow_no_value=True, strict=False)
        config.read_string(ini_data.encode('ascii', 'ignore').decode())

        for section in config.sections():
            for name, value in config.items(section, raw=True):
                self.values[name] = section

    # Downloads the external resource data
    def download(self, force: bool = False) -> Resource:
        if not self.resource_template:
            return

        # URL context
        context = {}
        version = self._find_latest_version(force=force)
        if version:
            context['version'] = version

        resource = self.resource_template.render(**context)
        resource.install(force=force)
        return resource

    # Looks for the version pattern in the content of the mame-support archive
    def _find_latest_version(self, force: bool = False) -> str:
        if not self.version_pattern:
            return

        archive_resource = self.MAME_ARCHIVE_RESOURCE.render()
        archive_resource.install(force=force)

        content = archive_resource.target_path.path.read_text()
        for line in content.split('\n'):
            match = re.search(self.version_pattern, line)
            if match:
                result = match.group(1)
                break

        return result

    # Gets the value for the given name / attribute
    def get_value(self, name, attribute, database):
        value = self.values.get(name)
        if value:
            return self._parse_value(value)

    # Runs any post-processing on the raw data from the external resource
    def _parse_value(self, value):
        return value
