from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import configparser
import json
import re
from pathlib import Path

class ExodosToDosboxStagingConf(BaseAction):
    name = 'exodos_to_dosbox_staging_conf'
    allow_stubbing = False

    AUTOEXEC_OPTION_REGEX = re.compile('^(.+)(\[autoexec\].+)$', re.M|re.DOTALL)
    EXODOS_REGEX = re.compile('exodos', re.IGNORECASE)

    def __init__(self, *args, **kwargs) -> None:
        super().__init__(*args, **kwargs)

        mappings_path = Path(self.config.get('mappings_file'))
        with mappings_path.open() as mappings_file:
            self.mappings = json.load(mappings_file)

        self.ignore_missing_configs = self.config.get('ignore_missing_configs') == 'true'

    # Converts an exodos dosbox.conf file to a configuration file compatible with
    # dosbox-staging
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        with source.path.open('r') as config_file:
            config_content = config_file.read()

            # Split out the non-[autoexec] sections from the [autoexec] section
            # 
            # This is done because ConfigParser will fail on the non-standard
            # content within the [autoexec] section.
            # 
            # [autoexec] will be added back to the config once the rest of the
            # file has been processed
            config_groups = re.search(self.AUTOEXEC_OPTION_REGEX, config_content)
            non_autoexec_content = config_groups.group(1)
            autoexec_content = config_groups.group(2)

        source_config = configparser.ConfigParser(strict=False)
        source_config.optionxform = str
        source_config.read_string(non_autoexec_content)

        target_config = configparser.ConfigParser()

        # Migrate config to one suitable for dosbox-staging
        self._map_sections(source_config, target_config)

        # Migrate autoexec content
        exodos_root_dir = self.config.get('rewrite_root', '')
        target_autoexec_content = ''
        for line in autoexec_content.split('\n'):
            if '\\exodos' in line.lower():
                # Replace the default exodos root with the one provided
                if exodos_root_dir:
                    line = self.EXODOS_REGEX.sub(exodos_root_dir, line)

            target_autoexec_content += f'{line}\n'

        # Consistent trailing newlines
        target_autoexec_content = target_autoexec_content.rstrip() + '\n'

        # Write the final translated configuration file
        with target.path.open('w') as config_file:
            target_config.write(config_file, space_around_delimiters=False)

            # Add back the [autoexec] section
            config_file.write(target_autoexec_content)

    # Maps sections from the source config
    def _map_sections(self, source_config: configparser.ConfigParser, target_config: configparser.ConfigParser) -> None:
        for section_name in source_config.sections():
            section_name = section_name.lower()
            self._map_section(source_config[section_name], target_config)

    # Maps the given section
    def _map_section(self, section: configparser.Section, target_config: configparser.ConfigParser) -> None:
        if section.name not in self.mappings and self.ignore_missing_configs:
            # Missing section ignored
            return

        mapper = self.mappings[section.name]

        if mapper.get('skip', False):
            # This section is skipped
            return

        for param, value in section.items():
            param = param.lower()
            self._map_param(section, param, target_config)

    # Maps the given parameter
    def _map_param(self, section: configparser.Section, param: str, target_config: configparser.ConfigParser) -> None:
        mapper = self.mappings[section.name]

        if param in mapper.get('skip_params', []):
            # Skipped
            return

        param_mapping = mapper['params'].get(param, {})

        # Identify target section / param name
        target_param = param_mapping.get('rename_to', param)
        if '/' in target_param:
            target_section, target_param = target_param.split('/')
        else:
            target_section = mapper.get('rename_to', section.name)

        # All params are lowercase
        target_param = target_param.lower()

        # Current value
        value = section.get(param, raw=True)

        # Map the value
        value_mappings = param_mapping.get('map_values', {})
        value_template = value_mappings.get(value, value_mappings.get('*'))
        if value_template is not None:
            value = eval(f"f\"{value_template}\"")

        # Skip if no value was set
        if value is None or value == '':
            return

        # Switch to the target section / param configuration
        mapper = self.mappings[target_section]
        if target_param not in mapper['params'] and self.ignore_missing_configs:
            # Missing param ignored
            return

        param_mapping = mapper['params'][target_param]

        # Skip if this is a default
        defaults = [str(default) for default in param_mapping['defaults']]
        if value in defaults:
            return

        # Fail if this is not in the allowlist
        allowlist = {str(allowed_value) for allowed_value in param_mapping.get('allowlist', [])}
        if allowlist and value not in allowlist:
            raise Exception(f'Invalid value for {target_section}/{target_param}: {value}')

        # Everything looks good!  Write to the target config

        # Ensure the section exists, otherwise `set` will fail
        if target_section not in target_config:
            target_config.add_section(target_section)

        # Replace windows-style slashes
        value = value.replace('\\', '/')

        # Ensure consistent case if the param isn't case-sensitive
        if not param_mapping.get('case_sensitive', False):
            value = value.lower()

        target_config.set(target_section, target_param, value)
