from __future__ import annotations

from typing import Type

def all_subclasses(cls):
    return set(cls.__subclasses__()).union(
        [s for c in cls.__subclasses__() for s in all_subclasses(c)])

class BaseAction:
    name = None
    overwrite_target = False

    def __init__(self, config: dict = {}) -> None:
      self.config = config
      # if not self.overwrite_target and config.get('overwrite_target'):
      self.overwrite_target = config.get('overwrite_target', self.overwrite_target)

    # Builds an action from the given JSON data
    @classmethod
    def from_json(cls, json: dict) -> BaseAction:
        json = json.copy()
        action = json.pop('action')
        return cls.for_name(action)(json)

    # Looks up the action from the given name
    @classmethod
    def for_name(cls, name: str) -> Type[BaseAction]:
        for subcls in all_subclasses(BaseAction):
            if subcls.name == name:
                return subcls

        raise Exception(f'Invalid action: {name}')

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        raise NotImplementedError()
