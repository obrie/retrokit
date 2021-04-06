# Authentication strategy
class BaseAuth:
    # Looks up the format from the given name
    @staticmethod
    def from_name(name):
        for cls in BaseAuth.__subclasses__():
            if cls.name == name:
                return cls

        return self

    # Does this authentication strategy match the given url?
    def match(self, url):
        return False

    # Headers to include in http requests
    @property
    def headers(self):
        return {}

    # Cookies to include in http requests
    @property
    def cookies(self):
        return {}
