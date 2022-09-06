from __future__ import annotations

# Authentication strategy
class BaseAuth:
    # Looks up the format from the given name
    @classmethod
    def from_name(cls, name: str) -> BaseAuth:
        for subcls in cls.__subclasses__():
            if subcls.name == name:
                return subcls()

        return cls()

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
