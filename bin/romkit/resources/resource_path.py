from pathlib import Path

# Represents a local path for a resource on the filesystem
class ResourcePath:
    extensions = []
    can_list_files = False
    
    # Looks up the format from the given path
    @staticmethod
    def from_path(resource, path):
        extension = Path(path).suffix[1:]

        for cls in ResourcePath.__subclasses__():
            if extension in cls.extensions:
                return cls(resource, path)

        return ResourcePath(resource, path)

    def __init__(self, resource, path):
        self.resource = resource
        self.path = path

    # Builds a file reference
    def build_file(self, name, crc):
        return self.resource.build_file(name, crc)

    # Lists files installed in this path
    def contains(self, files):
        if self.can_list_files:
            return self.exists() and not any(files - self.list_files())
        else:
            return self.exists()

    # Whether this path exists
    def exists(self):
        return Path(self.path).exists()

    # Symlinks this path to the given target
    def symlink(self, target):
        Path(target).symlink_to(self.path)

    def delete(self):
        if self.exists():
            Path(self.path).unlink()

    # Any necessary cleanup
    def clean(self, expected_files):
        pass

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
        return hash(self.path)
