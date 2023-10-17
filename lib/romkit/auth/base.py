from __future__ import annotations

# Authentication strategy
class BaseAuth:
    # Builds an authentication client from the given JSON data
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

    # Headers to include in http requests
    @property
    def headers(self) -> dict:
        return {}

    # Cookies to include in http requests
    @property
    def cookies(self) -> dict:
        return {}
