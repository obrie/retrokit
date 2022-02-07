from __future__ import annotations

from romkit.filters import FilterSet

from pathlib import Path

class SystemDir:
    def __init__(self, path: str, filter_set: FilterSet, file_templates: dict = {}) -> None:
        self.path = Path(path)
        self.filter_set = filter_set
        self.file_templates = file_templates

    # Whether the given machine should be enabled in this dir
    def allow(self, machine: Machine) -> bool:
        return self.filter_set.allow(machine)

    # Clears all existing symlinks in the directory
    def reset(self) -> None:
        if self.path.is_dir():
            # Remove all symbolic links within the directory; there could be other
            # things in the directory, so we want to avoid removing those.  We know
            # that symbolic links are what's managed by romkit.
            for filepath in self.path.iterdir():
                if filepath.is_symlink():
                    filepath.unlink()

    # Symlinks a resource with the given source path to this directory
    def symlink(self, resource_name: str, source: Path, **context) -> None:
        file_template = self.file_templates[resource_name]

        source_match = file_template.get('source')
        target = Path(file_template['target'].format(dir=self.path, **context))

        # Ensure target's parent exists
        target.parent.mkdir(parents=True, exist_ok=True)

        if not source_match:
            # Target is being directly linked
            target.unlink(missing_ok=True)
            target.symlink_to(source)
        elif source_match == '..':
            # Target is the parent directory
            target.unlink(missing_ok=True)
            target.symlink_to(source.parent, target_is_directory=True)
        elif source_match == '*':
            # Target is all files within source directory
            for source_filepath in source.iterdir():
                subtarget = target.joinpath(source_filepath.name)
                subtarget.unlink(missing_ok=True)
                subtarget.symlink_to(source_filepath)
        else:
            raise Exception(f'Invalid source match: {source_match} (must be None, "..", or "*"")')
