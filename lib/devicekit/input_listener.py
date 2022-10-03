import asyncio
import configparser
import evdev
import logging
import pyudev
import traceback
import xml

from pathlib import Path
from typing import Callable, NamedTuple

import devicekit.retroarch as retroarch
from devicekit.input_device import InputDevice, InputType

# Represents a callback to invoke when a given button is encountered
class Handler(NamedTuple):
    btn_name: str
    callback: Callable
    grabbed: bool
    hotkey: bool
    on_key_down: bool
    retroarch: bool
    repeat: bool

# Listens for key / button presses that trigger changes to devicekit
class InputListener():
    # Path to the Retroarch config for finding hotkeys
    RETROARCH_CONFIG_PATH = Path('/opt/retropie/configs/all/retroarch.cfg')

    def __init__(self,
        repeat_delay: float = 0.25,
        repeat_interval: float = 0.01,
        repeat_turbo_wait: float = 5.0,
    ) -> None:
        self.repeat_delay = repeat_delay
        self.repeat_interval = repeat_interval
        self.repeat_turbo_wait = repeat_turbo_wait

        # Defaults
        self.devices = []
        self.handlers = {InputType.KEYBOARD: [], InputType.JOYSTICK: []}
        self.grabbed = False

        self.event_loop = asyncio.get_event_loop()

    # Adds the input device at the given path to the list of devices we'll be
    # listening for events from
    def add_device(self, path: str) -> None:
        try:
            dev_device = evdev.InputDevice(path)
        except Exception as e:
            logging.warn('Failed to create evdev device: {e}')
            traceback.print_exc()
            return

        # Find the corresponding RetroArch configuration
        config = retroarch.Config.find_for_device(dev_device.name)
        if not config:
            if self._is_keyboard_device(dev_device):
                config = retroarch.Config()
            else:
                # Not a keyboard or known joystick -- abort
                logging.debug(f'Skipping device: {path} ({dev_device.name})')
                return

        # Build the input device
        input_device = InputDevice(
            dev_device,
            config.input_type,
            repeat_delay=self.repeat_delay,
            repeat_interval=self.repeat_interval,
            repeat_turbo_wait=self.repeat_turbo_wait,
            hotkey=config.hotkey,
        )

        # Bind handlers
        for handler in self.handlers[config.input_type]:
            if handler.retroarch:
                input_code = config.get_button(handler.btn_name)
            else:
                input_code = handler.btn_name

            if input_code:
                input_device.on(input_code, handler.callback, grabbed=handler.grabbed, hotkey=handler.hotkey, on_key_down=handler.on_key_down, repeat=handler.repeat)

        # Start listening for events
        self.devices.append(input_device)
        input_device.start_read(self.event_loop)

        # Sometimes devices are added while devicekit is running.  In that
        # case, we immediately grab control of the input so that everything
        # is redirected to this process.
        if self.grabbed:
            input_device.grab()

    # Executes a callback when the given buton is detected on the input type (keyboard / joystick)
    def on(self,
        # Joystick or keyboard?
        input_type: InputType,
        # The name of the retroarch button / retroarch key to listen for
        btn_name: str,
        # The handler function to execute
        callback: Callable,
        # Run the handler only when input has been focused? (i.e. grabbed)
        grabbed: bool = True,
        # Require the hotkey also be pressed?
        hotkey: bool = False,
        # Trigger when the key is pressed down or up?
        on_key_down: bool = True,
        # Whether btn_name is a retroarch config name or just a key name
        retroarch: bool = True,
        # Trigger repeats?
        repeat: bool = True,
    ):
        self.handlers[input_type].append(Handler(btn_name, callback, grabbed, hotkey, on_key_down, retroarch, repeat))

    # Removes and stops listening to events from the device at the given
    # filesystem path (/dev/input/eventX).
    def remove_device(self, path: str) -> None:
        device = next(filter(lambda device: device.path == path, self.devices), None)
        if device:
            device.stop_read()
            self.devices.remove(device)

    # Reloads the configuration for all current devices.  This will:
    # * Stop reading from the devices
    # * Reload the associated autoconfiguration for them
    # * Start listening to the devices again
    # 
    # This is intended to allow devicekit to sync up with the system when a new
    # joystick has been configured.
    def reload_devices(self) -> None:
        for device in self.devices:
            device.stop_read()

        self.devices.clear()

        for path in evdev.list_devices():
            self.add_device(path)

    # Listens for input events.  Note that this will loop infinitely.
    def listen(self) -> None:
        # Add currently known devices
        for path in evdev.list_devices():
            self.add_device(path)

        # Track devices that are added / removed
        context = pyudev.Context()
        monitor = pyudev.Monitor.from_netlink(context)
        monitor.filter_by(subsystem='input')
        observer = pyudev.MonitorObserver(monitor, self._handle_udev_event)
        observer.start()

        # Start receiving device events
        self.event_loop.set_exception_handler(self._handle_event_exception)
        self.event_loop.run_forever()

    # Checks for new /dev/input/eventX devices that have been added / removed
    # from the system and appropriately updates this listener.
    def _handle_udev_event(self, action: str, device: pyudev.Device) -> None:
        path = device.device_node
        if path and path.startswith('/dev/input/event'):
            if action == 'add':
                self.add_device(path)
            elif action == 'remove':
                self.remove_device(path)

    # Handles exceptions in asyncio loops by logging them.  This ensures
    # the event gets consumed.
    def _handle_event_exception(self, loop, context):
        message = context.get('exception', context['message'])
        logging.error(f'Caught exception: {context} {message}')

    # Stops the current asyncio loop so we stop receiving input events
    def stop(self) -> None:
        if self.event_loop:
            logging.debug('Stopping input listener')
            self.event_loop.stop()
            self.event_loop = None

    # Grabs control of all input devices so that events only get routed to this process
    def grab(self) -> None:
        for device in self.devices:
            device.grab()

        self.grabbed = True

    # Releases control of all input devices to the rest of the system
    def ungrab(self) -> None:
        for device in self.devices:
            device.ungrab()

        self.grabbed = False

    # Makes a best-effort attempt to see if the given device is a keyboard
    # 
    # There's no standard way to detect a keyboard, but it's a pretty good
    # bet that the device will report EV_REP as a capability.
    def _is_keyboard_device(self, device: evdev.InputDevice):
        return evdev.ecodes.EV_REP in device.capabilities().get(evdev.ecodes.EV_KEY, [])
