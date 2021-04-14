from romkit.resources.actions.base import BaseAction

import shutil

class Copy(BaseAction):
    name = 'copy'

    def install(self, source, target, **kwargs):
        if source.path != target.path:
            shutil.copyfile(source.path, target.path)
