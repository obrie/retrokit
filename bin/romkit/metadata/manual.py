from __future__ import annotations

from romkit.metadata.external import ExternalMetadata

import csv

# Manual availability
# 
# Format: TSV (default)
#  
# Columns:
# * 0 - ROM Name
# * 1 - Manual URL
class ManualMetadata(ExternalMetadata):
    name = 'manual'

    def load(self) -> None:
        # Look up which languages are supported for each flag
        self.flag_to_languages = self.config['languages']['flags']
        for flag, languages in self.flag_to_languages.items():
            self.flag_to_languages[flag] = set(languages)

        # Look up what languages the user wants to support
        self.languages = self.config['languages']['priority']

        # Look up the available manuals
        self.data = {}
        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                key = row[0]
                languages = row[1].split(',')
                url = row[2]

                if key not in self.data:
                    self.data[key] = {}

                manuals = self.data[key]
                for language in languages:
                    if language not in manuals:
                        manuals[language] = url

    def update(self, machine: Machine) -> None:
        manuals = self.data.get(machine.parent_title or machine.title)

        if manuals:
            # Find the unique flags
            flags = set(flag_part.strip() for flag_parts in machine.flags for flag_part in flag_parts.split(','))

            # Find the flags that have configured language mappings
            matching_flags = flags.intersection(self.flag_to_languages.keys())

            if matching_flags:
                # Look up the languages for the matching flags
                flag_languages = set().union(*(self.flag_to_languages[flag] for flag in matching_flags))
                possible_languages = [language for language in self.languages if language in flag_languages]
            else:
                # Use the default set of languages
                possible_languages = self.languages

            # Find a language that has a manual
            matching_language = next((language for language in possible_languages if language in manuals), None)
            if matching_language:
                machine.manual = {'language': matching_language, 'url': manuals[matching_language]}
