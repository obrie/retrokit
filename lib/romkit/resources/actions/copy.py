from __future__ import annotations

from romkit.resources.actions.base import BaseAction

import shutil

class Copy(BaseAction):
    name = 'copy'

    # Copies the file, as-is, from the source to the target path
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        if source != target:
            shutil.copyfile(source.path, target.path)
