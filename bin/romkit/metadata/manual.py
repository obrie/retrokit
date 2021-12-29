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

    FLAG_TO_LANGUAGES = {
      "Argentina": {"es"},
      "Asia": {"jp"},
      "Australia": {"en"},
      "Brazil": {"pt"},
      "Canada": {"en", "fr"},
      "English": {"en"},
      "Europe": {"de", "en-gb", "es", "fr", "it", "nl"},
      "France": {"fr"},
      "Germany": {"de"},
      "Italy": {"it"},
      "Japan": {"ja"},
      "Korea": {"kr"},
      "Netherlands": {"nl"},
      "New Zealand": {"en"},
      "Portugal": {"pt"},
      "Spain": {"es"},
      "Taiwan": {"tw"},
      "United Kingdom": {"en"},
      "USA": {"en"},
    }

    def load(self) -> None:
        if not self.install_path:
            return

        # Look up what languages the user wants to support
        self.languages = self.config['languages']['priority']

        # Priority preferences
        self.regional_priority = self.config['languages']['regional_priority']
        self.allow_fallback = self.config['languages']['allow_fallback']

        # Look up the available manuals
        self.data = {}
        with self.install_path.open() as file:
            rows = csv.reader(file, delimiter='\t')
            for row in rows:
                key = row[0]
                languages_str = row[1]
                languages = languages_str.split(',')
                url = row[2]
                options = row[3] if len(row) > 3 else None

                if key not in self.data:
                    self.data[key] = {}

                manuals = self.data[key]
                for language in languages:
                    if language not in manuals or len(languages_str) < len(manuals[language]['languages']):
                        manuals[language] = {"languages": languages_str, "url": url, "options": options}


    def update(self, machine: Machine) -> None:
        if not self.install_path:
            return

        manuals = self.data.get(machine.parent_title or machine.title)

        if manuals:
            # Use a dict, so we get fast lookups and ordered insertions
            candidate_languages = {}

            # Check if we should prioritize the regional languages before the
            # globally configured priority
            if self.regional_priority:
                # Find the unique flags
                all_flags = set(flag_part.strip() for flag_parts in machine.flags for flag_part in flag_parts.split(','))

                # Find the flags that have configured language mappings
                region_flags = all_flags.intersection(self.flag_to_languages.keys())
                region_languages = set().union(*(self.flag_to_languages[flag] for flag in region_flags))

                # Add all regional languages, ordered by global priority
                for language in self.languages:
                    if language in region_languages:
                        candidate_languages[language] = True

            if self.allow_fallback:
                # Add the default set of languages
                for language in self.languages:
                    candidate_languages[language] = True

            # Find a language that has a manual
            selected_language = next((language for language in candidate_languages.keys() if language in manuals), None)
            if selected_language:
                machine.manual = manuals[selected_language]
