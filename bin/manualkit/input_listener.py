import asyncio
import configparser
import evdev
import logging
import pyudev
import xml

from pathlib import Path
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
        joystick_toggle: str = 'h0up',
        repeat_delay: float = 0.25,
        repeat_interval: float = 0.01,
    ) -> None:
        self.on_toggle = on_toggle
        self.on_next = on_next
        self.on_prev = on_prev
        self.keyboard_toggle = keyboard_toggle
        self.joystick_toggle = joystick_toggle
        self.repeat_delay = float(repeat_delay)
        self.repeat_interval = float(repeat_interval)

        # Defaults
        self.devices = []
        self.active = False
        self.retroarch_config = self._read_retroarch_config(self.RETROARCH_CONFIG_PATH)

        self.event_loop = asyncio.get_event_loop()
        for path in evdev.list_devices():
            self.add_device(path)

    # Adds the input device at the given path to the list of devices we'll be
    # listening for events from
    def add_device(self, path: str) -> None:
        dev_device = evdev.InputDevice(path)
        autoconfig_path = Path(f'/opt/retropie/configs/all/retroarch/autoconfig/{dev_device.name}.cfg')

        if autoconfig_path.exists():
            # Treat it like a joystick
            joystick_config = self._read_retroarch_config(autoconfig_path)
            input_device = self.create_input_device(
                dev_device,
                InputType.JOYSTICK,
                hotkey=joystick_config.get('input_enable_hotkey_btn', fallback=None),
                toggle_input=self.joystick_toggle,
                next_input=joystick_config.get('input_right_btn', fallback='h0right'),
                prev_input=joystick_config.get('input_left_btn', fallback='h0left'),
            )
        else:
            # Treat it like a keyboard
            input_device = self.create_input_device(
                dev_device,
                InputType.KEYBOARD,
                hotkey=self.retroarch_config.get('input_enable_hotkey', fallback=None),
                toggle_input=self.keyboard_toggle,
                next_input=self.retroarch_config.get('input_player1_right', fallback='right'),
                prev_input=self.retroarch_config.get('input_player1_left', fallback='left'),
            )

        self.devices.append(input_device)

        # Start listening for events
        input_device.start_read(self.event_loop)

        # Sometimes devices are added while manualkit is running.  In that
        # case, we immediately grab control of the input so that everything
        # is redirected to this process.
        if self.active:
            input_device.grab()

    # Creates a new input device with default configurations and the given overrides
    def create_input_device(self, *args, **kwargs) -> InputDevice:
        return InputDevice(
            *args,
            on_toggle=self.toggle,
            on_next=self.next,
            on_prev=self.prev,
            repeat_delay=self.repeat_delay,
            repeat_interval=self.repeat_interval,
            **kwargs,
        )

    # Removes and stops listening to events from the device at the given
    # filesystem path (/dev/input/eventX).
    def remove_device(self, path: str) -> None:
        device = next(filter(lambda device: device.path == path, self.devices), None)
        if device:
            device.stop_read()
            self.devices.remove(device)

    # Listens for input events.  Note that this will loop infinitely.
    def listen(self) -> None:
        # Track devices that are added / removed
        context = pyudev.Context()
        monitor = pyudev.Monitor.from_netlink(context)
        monitor.filter_by(subsystem='input')
        observer = pyudev.MonitorObserver(monitor, self._handle_udev_event)
        observer.start()

        # Start receiving events
        self.event_loop.set_exception_handler(self._handle_exception)
        self.event_loop.run_forever()

    # Checks for new /dev/input/eventX devices that have been added / removed
    # from the system and appropriately updates this listener.
    def _handle_udev_event(self, action: str, device: pyudev.Device) -> None:
        if device.device_node and device.device_node.startswith('/dev/input/event'):
            if action == 'add':
                self.add_device(device.device_node)
            elif action == 'remove':
                self.remove_device(device.device_node)

    # Stops the current asyncio loop so we stop receiving input events
    def stop(self) -> None:
        if self.event_loop:
            self.event_loop.stop()
            self.event_loop = None

    # Toggles control of the devices and triggers the `on_toggle` callback
    def toggle(self):
        # Update control of the devices
        for device in self.devices:
            if self.active:
                device.ungrab()
            else:
                device.grab()

        self.active = not self.active

        # Trigger the callback
        self.on_toggle()

    # Triggers the `next` callback
    def next(self) -> None:
        self.on_next()

    # Triggers the `on_prev` callback
    def prev(self) -> None:
        self.on_prev()

    # Handles exceptions in asyncio loops by logging them.  This ensures
    # the event gets consumed.
    def _handle_exception(self, loop, context):
        message = context.get('exception', context['message'])
        logging.error(f'Caught exception: {context} {message}')

    # Reads the retroarch config file at the given path.  This handles the fact that
    # retroarch configurations don't have sections.
    def _read_retroarch_config(self, path: Path) -> configparser.SectionProxy:
        with path.open() as f:
            content = '[DEFAULT]\n' + f.read()

        config = configparser.ConfigParser()
        config.read_string(content)

        return config['DEFAULT']
