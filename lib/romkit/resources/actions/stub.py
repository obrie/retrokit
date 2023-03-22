from __future__ import annotations

from romkit.resources.actions.base import BaseAction

class Stub(BaseAction):
    name = 'stub'

    # Suffixes indicating a path is a directory instead of a file
    DIR_SUFFIXES = {'.daphne'}

    # Extracts files from the source to the target directory
    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        suffix = target.path.suffix
        if not suffix or suffix in self.DIR_SUFFIXES:
            target.path.mkdir(parents=True, exist_ok=True)
        else:
            target.path.parent.mkdir(parents=True, exist_ok=True)
            target.path.touch()

class StubDownloader():
    def get(self, source: str, destination: Path, force: bool = False) -> None:
        return
