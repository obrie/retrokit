import os
import re

from romkit.resources.resource import ResourceTemplate
from metakit.systems.arcade_data.base import ExternalData

# Number of players, managed by Arcade Belgium (includes clones)
class PlayersData(ExternalData):
    attribute = 'players'
    allow_clone_overrides = True
    resource_template = ResourceTemplate.from_json({
        'source': 'http://nplayers.arcadebelgium.be/files/nplayers0246.zip',
        'download': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/nplayers.zip',
        'target': f'{os.environ["RETROKIT_HOME"]}/tmp/arcade/nplayers.ini',
        'install': {
            'action': 'zip_extract',
            'file': 'folders/Multiplayer.ini'
        }
    })

    def _parse_value(self, value):
        # Find all player configurations (e.g. "4P alt / 2P sim" = ["4", "2"])
        players_list = [int(s) for s in re.findall(r'\d+', value)]
        if players_list:
            # Get the largest number of players supported
            return sorted(players_list)[-1]
