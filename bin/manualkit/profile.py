import distutils.util

# Represents a configuration profile to use (specifically for toggling)
class Profile():
    def __init__(self,
        name: str,
        enabled: bool = True,
        suspend: bool = True,
        hotkey_enable: bool = True,
    ) -> None:
        self.name = name
        self.enabled = distutils.util.strtobool(str(enabled)) == 1
        self.suspend = distutils.util.strtobool(str(suspend)) == 1
        self.hotkey_enable = distutils.util.strtobool(str(hotkey_enable)) == 1
