import asyncio
import configparser
import evdev
import logging
import xml

from typing import Callable

from manualkit.input_device import InputDevice, InputType

# Listens for key / button presses that trigger changes to manualkit
class InputListener():
    # Path to the Retroarch config for finding hotkeys
    RETROARCH_CONFIG_PATH = Path('/opt/retropie/configs/all/retroarch.cfg')

    def __init__(self,
        on_toggle: Callable,
        on_next: Callable,
        on_prev: Callable,
        keyboard_toggle: str = 'm',
        joystick_toggle: str = 'up',
    ) -> None:
        self.devices = []
        self.active = False
        self.loop = None

        # Keyboard config (default to those defined in Retroarch)
        retroarch_config = self._read_retroarch_config(self.RETROARCH_CONFIG_PATH)

        for device in [evdev.InputDevice(path) for path in evdev.list_devices()]:
            autoconfig_path = Path(f'/home/retropie/configs/all/retroarch/autoconfig/{device.name}.cfg')
            if autoconfig_path.exists():
                # Treat it like a joystick
                joystick_config = self._read_retroarch_config(autoconfig_path)
                self.devices.append(InputDevice(
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
                self.devices.append(InputDevice(
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

        # Start receiving events
        self.loop = asyncio.get_event_loop()
        self.loop.set_exception_handler(self._handle_exception)
        try:
            self.loop.run_forever()
        finally:
            self.loop.close()

    # Stops the current asyncio loop so we stop receiving input events
    def stop(self) -> None:
        if self.loop:
            self.loop.stop()
            self.loop = None

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

    # Handles exceptions in asyncio loops by logging them.  This ensures
    # the event gets consumed.
    def _handle_exception(self, loop, context):
        message = context.get('exception', context['message'])
        logging.error(f'Caught exception: {message}')

    # Reads the retroarch config file at the given path.  This handles the fact that
    # retroarch configurations don't have sections.
    def _read_retroarch_config(self, path: Path) -> configparser.SectionProxy:
        with path.open() as f:
            content = '[DEFAULT]\n' + f.read()

        config = configparser.ConfigParser()
        config.read_string(content)

        return config['DEFAULT']
