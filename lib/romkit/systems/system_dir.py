from __future__ import annotations

from romkit.filters import FilterSet

import os
from pathlib import Path

class SystemDir:
    def __init__(self,
        path: str,
        filter_set: FilterSet,
        context: dict = {},
        file_templates: dict = {},
    ) -> None:
        self.path = Path(path)
        self.filter_set = filter_set
        self.context = context
        self.file_templates = file_templates

    # Whether the given machine should be enabled in this dir
    def allow(self, machine: Machine) -> bool:
        return self.filter_set.allow(machine)

    # Clears all existing symlinks in the directory
    def reset(self) -> None:
        # Define a context that will match all potential candidates
        context = {
            'machine': '*',
            'machine_filename': '*',
            'playlist_filename': '*',
        }

        if self.path.is_dir():
            for resource_name, file_template in self.file_templates.items():
                path_glob = Path(file_template['target'].format(
                    dir=self.path,
                    **context,
                    **self.context,
                ))

                # Remove all symbolic links within the directory; there could be other
                # things in the directory, so we want to avoid removing those.  We know
                # that symbolic links are what's managed by romkit when it matches the
                # file template target pattern.
                for filepath in Path('/').glob(str(path_glob)[1:]):
                    if filepath.is_symlink():
                        filepath.unlink()

    # Symlinks a resource with the given source path to this directory
    def symlink(self, resource_name: str, resource: Resource, **context) -> None:
        file_template = self.file_templates[resource_name]

        source = Path(file_template.get('source', '{target_path}').format(
            target_path=resource.target_path.path,
            xref_path=(resource.xref_path and resource.xref_path.path or ''),
        )).resolve()
        target = Path(file_template['target'].format(
            dir=self.path,
            **context,
            **self.context,
        ))

        # Ensure target's parent exists
        target.parent.mkdir(parents=True, exist_ok=True)

        if str(source)[-1] == '*':
            for source_filepath in source.parent.iterdir():
                subtarget = target.joinpath(source_filepath.name)
                if os.path.lexists(subtarget):
                    subtarget.unlink()
                subtarget.symlink_to(source_filepath)
        else:
            if os.path.lexists(target):
                target.unlink()
            target.symlink_to(source)
