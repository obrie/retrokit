import asyncio
import configparser
import evdev
import xml

import manualkit.keycodes

def to_evcodes(retroarch_codes: List[str]) -> List[int]:


# Listens for hotkeys that trigger changes to manualkit
class InputListener():
    # Path to the Retroarch config for finding hotkeys
    RETROARCH_CONFIG_PATH = Path('/opt/retropie/configs/all/retroarch.cfg')

    def __init__(self,
        keyboard_toggle: str = 'm',
        joystick_toggle: str = 'up',
    ) -> None:
        self.keyboard_toggle = keyboard_toggle
        self.joystick_toggle = joystick_toggle
        self.mappings = {}

        # Keyboard config
        retroarch_config = self._read_retroarch_config(self.RETROARCH_CONFIG_PATH)
        self.map(
            'keyboard',
            hotkey=retroarch_config.get('input_enable_hotkey', fallback=None),
            next=retroarch_config.get('input_player1_right', fallback='right').strip('"'),
            prev=retroarch_config.get('input_player1_left', fallback='left').strip('"'),
        )

        # Joystick config
        for device in self.devices:
            autoconfig_path = Path(f'/home/retropie/configs/all/retroarch/autoconfig/{device.name}.cfg')
            if autoconfig_path.exists():
                joystick_config = self._read_retroarch_config(autoconfig_path)
                hotkeys = []
                if 'input_enable_hotkey' in joystick_config:
                    hotkeys.append(joystick_config['input_enable_hotkey'])
                self.mappings[device.name] = {
                    'toggle': hotkeys + [self.joystick_toggle],
                    'next': hotkeys + [retroarch_config.get('input_right_btn', fallback='right').strip('"')],
                    'prev': hotkeys + [retroarch_config.get('input_left_btn', fallback='left').strip('"')],
                }
            else:
                # Treat it like a keyboard
                self.mappings[device.name] = default_keyboard_mapping

    # Looks up the list of available input interfaces
    @property
    def devices(self):
        return [evdev.InputDevice(path) for path in evdev.list_devices()]

    # 
    def listen(self):
        for device in self.devices:
            asyncio.ensure_future(self._handle_events(device))

        loop = asyncio.get_event_loop()
        loop.run_forever()        

    async def _handle_events(device):
        async for event in device.async_read_loop():
            print(device.path, evdev.categorize(event), sep=': ')

    def _retroarch_key(self, config: configparser.SectionProxy, name: str, fallback: Optional[int]) -> int:
        if name in config:
            keycode = 

    # Reads the retroarch config file at the given path.  This handles the fact that
    # retroarch configurations don't have sections.
    def _read_retroarch_config(self, path: Path) -> configparser.SectionProxy:
        with path.open() as f:
            content = '[DEFAULT]\n' + f.read()

        config = configparser.ConfigParser()
        config.read_string(content)

        return config['DEFAULT']
