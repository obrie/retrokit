from __future__ import annotations

from romkit.resources.actions.base import BaseAction
from romkit.resources.resource_path import ResourcePath

import tempfile
from pathlib import Path

# Provides the ability to chain multiple actions together
class Composite(BaseAction):
    name = 'composite'

    # Copies the file, as-is, from the source to the target path
    def install(self, source: ResourcePath, target: ResourcePath, force: bool = False, **kwargs) -> None:
        actions = [BaseAction.from_json({**self.config, **action}) for action in self.config['actions']]
        intermediate_source = intermediate_target = source

        with tempfile.TemporaryDirectory() as tmp_dir:
            for index, action in enumerate(actions):
                if index == len(actions) - 1:
                    # Last action -- install to the target
                    action.install(intermediate_source, target)
                else:
                    # Intermediate action -- install temporarily until we get to the final action
                    if 'target' in action.config:
                        intermediate_target_path = Path(action.config['target'])
                    else:
                        intermediate_target_path = Path(tmp_dir).joinpath(f'{index}.target')

                    intermediate_target = ResourcePath.from_path(intermediate_source.resource, intermediate_target_path)

                    # Install only if we need to
                    if force or not intermediate_target.exists():
                        action.install(intermediate_source, intermediate_target)

                    intermediate_source = intermediate_target
