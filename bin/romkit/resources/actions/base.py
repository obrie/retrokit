from __future__ import annotations

from typing import Type

class BaseAction:
    name = None

    def __init__(self, config: dict = {}) -> None:
      self.config = config

    # Builds an action from the given JSON data
    @classmethod
    def from_json(cls, json: dict) -> BaseAction:
        json = json.copy()
        action = json.pop('action')
        return cls.for_name(action)(json)

    # Looks up the action from the given name
    @classmethod
    def for_name(cls, name: str) -> Type[BaseAction]:
        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls

        raise Exception(f'Invalid action: {name}')

    def install(self, source: ResourcePath, target: ResourcePath, **kwargs) -> None:
        raise NotImplementedError()
