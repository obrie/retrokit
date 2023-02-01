from __future__ import annotations

from romkit.resources.actions.base import BaseAction

from urllib.parse import unquote

class PlaylistToM3U(BaseAction):
    name = 'playlist_to_m3u'
    overwrite_target = True

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        if self.config.get('relative_to'):
            source_path = source.path.relative_to(self.config.get('relative_to'))
        else:
            source_path = source.path

        with target.path.open('a+') as file:
            # Read/sort the paths
            file.seek(0)
            paths = file.readlines()
            paths.append(f'{unquote(str(source_path))}\n')
            paths.sort()

            # Write the new path list
            file.seek(0)
            file.truncate()
            file.write(''.join(paths))
