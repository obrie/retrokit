from __future__ import annotations

from metakit.attributes.base import BaseAttribute
from metakit.models.language import Language

from collections import defaultdict

class ManualsAttribute(BaseAttribute):
    name = 'manuals'

    KEYS = ['name', 'languages', 'url', 'options']
    OPTIONS_KEYS = ['filter', 'format', 'pages', 'rotate', 'rewrite_exif']
    FORMAT_VALUES = {
        'pdf',
        '7z', 'rar', 'zip',
        'doc', 'docx', 'rtf',  'wri',
        'html', 'txt',
        'jpeg', 'jpg', 'gif', 'png',
    }
    ROTATE_VALUES = {0, 90, 180, 270}
    REWRITE_EXIF_VALUES = {True, False}

    def validate(self, value: List[dict]) -> List[str]:
        errors = []

        languages_seen = defaultdict(set)

        for manual in value:
            if 'name' in manual and manual['name'] not in self.romkit.names and manual['name'] not in self.romkit.titles:
                errors.append(f"manual name not found: {manual['name']}")

            if 'languages' not in manual:
                errors.append('manual languages missing')

            for language in manual['languages']:
                if language not in Language.CODES:
                    errors.append(f"manual language not valid: {language}")

            name = manual.get('name', None)
            if frozenset(manual['languages']) in languages_seen[name]:
                errors.append(f"manual conflict: {manual['languages']}")

            languages_seen[name].add(frozenset(manual['languages']))

            if 'url' not in manual:
                errors.append('manual url missing')

            if 'options' in manual:
                options = manual['options']

                if 'format' in options and options['format'] not in self.FORMAT_VALUES:
                    errors.append(f"manual format not valid: {options['format']}")

                if 'rotate' in options and options['rotate'] not in self.ROTATE_VALUES:
                    errors.append(f"manual rotate not valid: {options['rotate']}")

                if 'rewrite_exif' in options and options['rewrite_exif'] not in self.REWRITE_EXIF_VALUES:
                    errors.append(f"manual rewrite_exif not valid: {options['rewrite_exif']}")

                invalid_keys = options.keys() - self.OPTIONS_KEYS
                if invalid_keys:
                    errors.append(f"manual options not valid: {invalid_keys}")

            invalid_keys = manual.keys() - self.KEYS
            if invalid_keys:
                errors.append(f"manual config not valid: {invalid_keys}")

        return errors

    def format(self, value: dict) -> List[str]:
        manuals = []

        for manual in value:
            manual = self._sort_dict(manual, self.KEYS)
            manuals.append(manual)

            if 'options' in manual:
                manual['options'] = self._sort_dict(manual['options'], self.OPTIONS_KEYS)

                if manual['options'].get('rotate') == 0:
                    del manual['options']['rotate']

        return sorted(manuals, key=lambda manual: [manual.get('name', ''), len(manual['languages']), ','.join(manual['languages'])])

    def clean(self, group: str, value: dict) -> None:
        for manual in value:
            if 'name' in manual and manual['name'] == group:
                del manual['name']
