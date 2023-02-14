import os
import re

from romkit.resources.resource import ResourceTemplate
from metakit.systems.arcade_data.base import ExternalData

# User rating metadata managed by progretto-SNAPS
class RatingData(ExternalData):
    attribute = 'rating'
    allow_clone_overrides = True
    resource_template = ResourceTemplate.from_json({
        'source': 'https://archive.org/download/mame-support/Support/Support-Files/pS_BestGames_{version}.zip/folders%2Fbestgames.ini',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/bestgames.ini',
    })
    version_pattern = r'pS_BestGames_([0-9]+).zip'

    RATING_PATTERN = r'^([0-9]+)'

    def _parse_value(self, value):
        return int(re.search(self.RATING_PATTERN, value).group(1))
