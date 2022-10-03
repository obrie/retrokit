import configparser
from pathlib import Path
from typing import Any, Callable, NamedTuple, Optional

from devicekit.input_type import InputType

class ButtonConfig(NamedTuple):
    btn_prefix: str
    btn_suffix: str
    hotkey_config_name: str

class Config:
    # Path to the global RetroArch configuration
    GLOBAL_CONFIG_PATH = Path('/opt/retropie/configs/all/retroarch.cfg')

    # Path to the directory containing device-specific autoconfigurations
    AUTOCONFIG_DIR = Path('/opt/retropie/configs/all/retroarch/autoconfig')

    # Config name structure for each device type for looking up inputs
    BUTTON_CONFIGS = {
        InputType.JOYSTICK: ButtonConfig('input_', '_btn', 'input_enable_hotkey_btn'),
        InputType.KEYBOARD: ButtonConfig('input_player1_', '', 'input_enable_hotkey'),
    }

    def __init__(self, path: str = GLOBAL_CONFIG_PATH, input_type: InputType = InputType.KEYBOARD):
        self.path = path
        with self.path.open() as f:
            content = '[DEFAULT]\n' + f.read()

        config = configparser.ConfigParser(strict=False)
        config.read_string(content)
        self._config_dict = dict(config['DEFAULT'].items())
        for key, value in self._config_dict.items():
            self._config_dict[key] = self._config_dict[key].strip('"')

        self.input_type = input_type

    # Looks up the autoconfiguration file for the given device
    @classmethod
    def find_for_device(cls, device_name: str) -> Path:
        # Prioritize a matching named configuration
        device_path = cls.AUTOCONFIG_DIR.joinpath(f'{device_name}.cfg')
        if device_path.exists():
            # Treat it like a joystick
            return cls(device_path, InputType.JOYSTICK)

    # The hotkey defined in the current configuration
    @property
    def hotkey(self) -> Optional[str]:
        return self.get(self._button_config.hotkey_config_name)

    @property
    def _button_config(self) -> ButtonConfig:
        return self.BUTTON_CONFIGS[self.input_type]

    # Reads the given key from the current config
    def get(self, key: str) -> Optional[Any]:
        return self._config_dict.get(key)

    # Reads the configuration key associated with the given button name
    def get_button(self, btn_name: str) -> str:
        button_config = self._button_config
        return self.get(f'{button_config.btn_prefix}{btn_name}{button_config.btn_suffix}')
