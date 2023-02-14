import os

from romkit.resources.resource import ResourceTemplate
from metakit.models.language import Language
from metakit.systems.arcade_data.base import ExternalData

# Language metadata managed by progretto-SNAPS (includes clones)
class LanguagesData(ExternalData):
    attribute = 'languages'
    allow_clone_overrides = True
    resource_template = ResourceTemplate.from_json({
        'source': 'https://archive.org/download/mame-support/Support/Support-Files/pS_Languages_{version}.zip/folders%2Flanguages.ini',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/languages.ini',
    })
    version_pattern = r'pS_Languages_([0-9]+).zip'

    def _parse_value(self, value):
        return [Language.NAME_TO_CODE[value]]
