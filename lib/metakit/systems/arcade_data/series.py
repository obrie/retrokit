import os

from romkit.resources.resource import ResourceTemplate
from metakit.systems.arcade_data.base import ExternalData

# Series metadata managed by progretto-SNAPS
class SeriesData(ExternalData):
    attribute = 'series'
    allow_clone_overrides = False
    resource_template = ResourceTemplate.from_json({
        'source': 'https://archive.org/download/mame-support/Support/Support-Files/pS_Series_{version}.zip/folders%2Fseries.ini',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/series.ini',
    })
    version_pattern = r'pS_Series_([0-9]+).zip'

    def _parse_value(self, value):
        return value
