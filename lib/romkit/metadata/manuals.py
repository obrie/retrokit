from __future__ import annotations

from romkit.metadata.base import BaseMetadata

# Location and configuration for physical manual scans
class ManualsMetadata(BaseMetadata):
    name = 'manuals'

    FLAG_TO_LANGUAGES = {
      'Argentina': {'es'},
      'Asia': {'jp'},
      'Australia': {'en', 'en-au'},
      'Brazil': {'pt'},
      'Canada': {'en', 'en-ca', 'fr'},
      'China': {'zh'},
      'Denmark': {'da'},
      'English': {'en'},
      'Europe': {'de', 'en', 'en-gb', 'es', 'fr', 'it', 'nl'},
      'Finland': {'fi'},
      'France': {'fr'},
      'Germany': {'de'},
      'Italy': {'it'},
      'Japan': {'ja'},
      'Korea': {'ko'},
      'Netherlands': {'nl'},
      'New Zealand': {'en'},
      'Norway': {'no'},
      'Poland': {'pl'},
      'Portugal': {'pt'},
      'Russia': {'ru'},
      'Spain': {'es'},
      'Sweden': {'sv'},
      'Taiwan': {'tw'},
      'United Kingdom': {'en', 'en-gb'},
      'USA': {'en'},
    }

    # Unique list of all language codes available
    ALL_LANGUAGE_CODES = ['ar', 'cs', 'da', 'de', 'en', 'en-au', 'en-ca', 'en-gb', 'es', 'fi', 'fr', 'it', 'ja', 'ko', 'nl', 'no', 'pl', 'pt', 'ru', 'sv', 'zh']

    def load(self) -> None:
        # Look up what languages the user wants to allow
        self.allowlist = self.config['languages'].get('allowlist') or self.ALL_LANGUAGE_CODES

        # Priority preferences
        self.prioritize_region_languages = self.config['languages']['prioritize_region_languages']
        self.only_region_languages = self.config['languages']['only_region_languages']

    def update(self, machine: Machine, manuals: List[dict]) -> None:
        # Use a dict, so we get fast lookups and ordered insertions
        candidate_languages = {}

        # Check if we should prioritize the regional languages before the
        # globally configured priority
        if self.prioritize_region_languages or self.only_region_languages:
            # Find the unique flags
            all_flags = set(flag_part.strip() for flag_parts in machine.flags for flag_part in flag_parts.split(','))

            # Find the flags that have configured language mappings
            region_flags = all_flags.intersection(self.FLAG_TO_LANGUAGES.keys())
            region_languages = set().union(*(self.FLAG_TO_LANGUAGES[flag] for flag in region_flags))

            # Add all regional languages, ordered by global priority
            for language in self.allowlist:
                if language in region_languages:
                    candidate_languages[language] = True

        # Add the full set of allowed languages
        if not self.only_region_languages:
            for language in self.allowlist:
                candidate_languages[language] = True

        # Find the first manual that has a candidate language
        fallback_manual = None
        for language in candidate_languages.keys():
            for manual in manuals:
                if language in manual['languages']:
                    if 'name' in manual:
                        if machine.name == manual['name'] or machine.title == manual['name']:
                            machine.manual = manual
                            return
                        else:
                            continue

                    if not fallback_manual:
                        fallback_manual = manual

        machine.manual = fallback_manual
