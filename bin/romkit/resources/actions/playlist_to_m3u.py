from __future__ import annotations

from romkit.resources.actions.base import BaseAction

from urllib.parse import unquote

class PlaylistToM3U(BaseAction):
    name = 'playlist_to_m3u'

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        with target.path.open('a+') as file:
            # Read/sort the paths
            file.seek(0)
            paths = file.readlines()
            paths.append(f'{unquote(str(source.path))}\n')
            paths.sort()

            # Write the new path list
            file.seek(0)
            file.truncate()
            file.write(''.join(paths))
