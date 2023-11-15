from __future__ import annotations

# Middleware for injecting additional data into Downloader requests
class BaseMiddleware:
    # Builds middleware from the given JSON data
    @classmethod
    def from_json(cls, json: dict, **kwargs) -> BaseAuth:
        return cls.for_name(json['type'])(
            **kwargs,
        )

    # Looks up the auth from the given name
    @classmethod
    def for_name(cls, name) -> Type[BaseAuth]:
        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls

        raise Exception(f'Invalid auth: {name}')

    # Does this authentication strategy match the given url?
    def match(self, url: str) -> bool:
        return False

    # Session configuration overrides to include
    @property
    def overrides(self) -> dict:
        return {}
