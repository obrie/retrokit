from __future__ import annotations

from romkit.processing import Ruleset

import logging
import os
from pathlib import Path

class SystemDir:
    def __init__(self,
        path: str,
        rules: Ruleset,
        context: dict = {},
        file_templates: dict = {},
    ) -> None:
        self.path = Path(path)
        self.rules = rules
        self.context = context
        self.file_templates = file_templates

    # Whether the given machine should be enabled in this dir
    def allow(self, machine: Machine) -> bool:
        return self.rules.match(machine) is not None

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
                self._symlink_file(source_filepath, target.joinpath(source_filepath.name))
        else:
            self._symlink_file(source, target)

    # Symlinks the given source path to the given target path *only* if the target
    # either doesn't exist or is a symlink.  We never want to risk overwriting the
    # user's actual files / directories.
    def _symlink_file(self, source: Path, target: Path) -> None:
        if os.path.exists(target) and not target.is_symlink():
            logging.warn(f'[{target.stem}] Failed to create symlink at {target} (file exists and is not symlink)')
        else:
            if os.path.lexists(target):
                target.unlink()
            target.symlink_to(source)
