import asyncio
import configparser
import evdev
import logging
import xml
from enum import Enum

import manualkit.keycodes

from typing import List

# Represents the type of input that we're listening to
class InputType(Enum):
    KEYBOARD = 'keyboard'
    JOYSTICK = 'joystick'

# Represents an evdev device that we're listening for events from
class InputDevice():
    VALID_ABS_CODES = {evdev.ecodes.ABS_HAT0X, evdev.ecodes.ABS_HAT0Y}

    def __init__(self,
        dev_device: evdev.InputDevice,
        input_type: InputType,
        hotkey: Optional[str],
        toggle_input: str,
        next_input: str,
        prev_input: str,
        on_toggle: Callable,
        on_next: Callable,
        on_prev: Callable,
    ) -> None:
        self.dev_device = dev_device
        self.on_toggle = on_toggle
        self.on_next = on_next
        self.on_prev = on_prev
        self.watch_navigation = False

        # Adjust for configparser issues
        hotkey = hotkey.strip('"')
        toggle_input = toggle_input.strip('"')
        next_input = next_input.strip('"')
        prev_input = prev_input.strip('"')

        # Define expected evdev inputs
        if input_type == InputType.KEYBOARD:
            retroarch_codes = manualkit.keycodes.retroarch_keyboard
        else:
            retroarch_codes = manualkit.keycodes.retroarch_joystick

        self.toggle_inputs = dict((retroarch_codes[toggle_input]))
        if hotkey:
            code, value = retroarch_codes[hotkey]
            self.toggle_inputs[code] = value

        self.next_inputs = dict((retroarch_codes[next_input]))
        self.prev_inputs = dict((retroarch_codes[prev_input]))

        # List codes that might trigger logic
        self.valid_codes = set(map(lambda name: retroarch_codes[name][0], [toggle_input, next_input, prev_input]))

        # Track which inputs are currently being pressed.  An input is removed
        # when a "up" value is received for the input.
        self.active_inputs = {}

    # Interprets events coming from evdev devices to determine if they should
    # change manualkit behavior
    async def read(self) -> None:
        async for event in self.dev_device.async_read_loop():
            # High-performance lookup to see if we should run more logic
            if event.type == ecodes.EV_KEY or (event.type == ecodes.EV_ABS and event.code in VALID_ABS_CODES):
                if event.value != 0:
                    # Key pressed
                    self.active_inputs[event.code] = event.value
                    self.check_inputs(event)
                else:
                    # Key released
                    self.active_inputs.pop(event.code)

    # Check the currently active inputs to see if they should trigger an event
    def check_inputs(self, event: evdev.InputEvent) -> None:
        if event.code not in self.valid_codes:
            return

        if self.active_inputs == self.toggle_inputs:
            self.on_toggle()
        elif self.watch_navigation:
            if self.active_inputs == self.next_inputs:
                self.on_next()
            elif self.active_inputs == self.prev_inputs:
                self.on_prev()

    # Grabs control of the current device so that events only get routed to this process
    def grab(self):
        self.watch_navigation = True

        try:
            self.raw_device.grab()
        except Exception as e:
            logging.warn(f'Failed to grab device: {self.raw_device.name} ({e})')

    # Releases control of the current device to the rest of the system
    def ungrab(self):
        self.watch_navigation = False

        try:
            self.raw_device.ungrab()
        except Exception as e:
            logging.warn(f'Failed to ungrab device: {self.raw_device.name} ({e})')

# Listens for key / button presses that trigger changes to manualkit
class InputListener():
    # Path to the Retroarch config for finding hotkeys
    RETROARCH_CONFIG_PATH = Path('/opt/retropie/configs/all/retroarch.cfg')

    def __init__(self,
        keyboard_toggle: str = 'm',
        joystick_toggle: str = 'up',
        on_toggle: Callable,
        on_next: Callable,
        on_prev: Callable,
    ) -> None:
        self.devices = []
        self.active = False

        # Keyboard config (default to those defined in Retroarch)
        retroarch_config = self._read_retroarch_config(self.RETROARCH_CONFIG_PATH)

        for device in [evdev.InputDevice(path) for path in evdev.list_devices()]:
            autoconfig_path = Path(f'/home/retropie/configs/all/retroarch/autoconfig/{device.name}.cfg')
            if autoconfig_path.exists():
                # Treat it like a joystick
                joystick_config = self._read_retroarch_config(autoconfig_path)
                self.devices.add(InputDevice(
                    device,
                    InputType.JOYSTICK,
                    hotkey=joystick_config.get('input_enable_hotkey', fallback=None),
                    toggle_input=joystick_toggle,
                    next_input=joystick_config.get('input_right_btn', fallback='h0right'),
                    prev_input=joystick_config.get('input_left_btn', fallback='h0left'),
                    on_toggle=self.toggle,
                    on_next=self.next,
                    on_prev=self.prev,
                ))
            else:
                # Treat it like a keyboard
                self.devices.add(InputDevice(
                    device,
                    InputType.KEYBOARD,
                    hotkey=retroarch_config.get('input_enable_hotkey', fallback=None),
                    toggle_input=keyboard_toggle,
                    next_input=retroarch_config.get('input_player1_right', fallback='right'),
                    prev_input=retroarch_config.get('input_player1_left', fallback='left'),
                    on_toggle=self.toggle,
                    on_next=self.next,
                    on_prev=self.prev,
                ))

    # Listens for input events.  Note that this will loop infinitely.
    def listen(self) -> None:
        for device in self.devices:
            asyncio.ensure_future(device.read())

        loop = asyncio.get_event_loop()
        loop.run_forever()        

    # Toggles control of the devices and triggers the `on_toggle` callback
    def toggle(self):
        # Remove control of the devices
        for device in self.devices:
            if self.active:
                device.ungrab()
            else:
                device.grab()

        self.active = not self.active

        # Trigger the callback
        self.on_toggle()

    # Triggers the `next` callback
    def next(self):
        self.on_next()

    # Triggers the `on_prev` callback
    def prev(self):
        self.on_prev()

    # Reads the retroarch config file at the given path.  This handles the fact that
    # retroarch configurations don't have sections.
    def _read_retroarch_config(self, path: Path) -> configparser.SectionProxy:
        with path.open() as f:
            content = '[DEFAULT]\n' + f.read()

        config = configparser.ConfigParser()
        config.read_string(content)

        return config['DEFAULT']
