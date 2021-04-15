from __future__ import annotations

from pathlib import Path
from typing import Set

# Represents a local path for a resource on the filesystem
class ResourcePath:
    extensions = []
    can_list_files = False
    
    # Looks up the format from the given path
    @classmethod
    def from_path(cls, resource: Resource, path: Path) -> ResourcePath:
        extension = Path(path).suffix[1:]
        return cls.for_extension(extension)(resource, path)

    # Looks up the discovery from the given name
    @classmethod
    def for_extension(cls, extension: str) -> Type[ResourcePath]:
        for subcls in cls.__subclasses__():
            if extension in subcls.extensions:
                return subcls

        return cls

    def __init__(self, resource: Resource, path: Path) -> None:
        self.resource = resource
        self.path = path

    # Builds a file reference
    def build_file(self, name: str, crc: str) -> File:
        return self.resource.build_file(name, crc)

    # Lists files installed in this path
    def contains(self, files: Set[File]) -> bool:
        if self.can_list_files:
            return self.exists() and not any(files - self.list_files())
        else:
            return self.exists()

    # Whether this path exists
    def exists(self) -> bool:
        return self.path.exists()

    # Deletes this path if it exists
    def delete(self) -> None:
        if self.exists():
            self.path.unlink()

    # Any necessary cleanup
    def clean(self, expected_files: Set[File]) -> None:
        pass

    # Lists files contained in this resource path
    def list_files(self) -> Set[File]:
        raise NotImplementedError

    ##############
    # Equality
    ##############

    # Equality based on Path
    def __eq__(self, other):
        if isinstance(other, ResourcePath):
            return self.path == other.path
        return False

    # Hash based on Path
    def __hash__(self):
        return self.path.__hash__()
