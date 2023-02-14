import os

from romkit.resources.resource import ResourceTemplate
from metakit.systems.arcade_data.base import ExternalData

# Genre metadata managed by progretto-SNAPS (includes clones)
class GenresData(ExternalData):
    attribute = 'genres'
    allow_clone_overrides = False
    resource_template = ResourceTemplate.from_json({
        'source': 'https://archive.org/download/mame-support/Support/Support-Files/pS_CatVer_{version}.zip/UI_files%2Fcatlist.ini',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/genres.ini',
    })
    version_pattern = r'pS_CatVer_([0-9]+).zip'

    def _parse_value(self, value):
        return [value.replace('Arcade: ', '')]
