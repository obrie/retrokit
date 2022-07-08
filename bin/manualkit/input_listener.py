import asyncio
import configparser
import evdev
import logging
import pyudev
import traceback
import xml

from pathlib import Path
from typing import Callable, NamedTuple

from manualkit.input_device import InputDevice, InputType

# Represents a callback to invoke when a given button is encountered
class Handler(NamedTuple):
    btn_name: str
    callback: Callable
    grabbed: bool
    hotkey: bool
    retroarch: bool
    on_key_down: bool
    repeat: bool

# Listens for key / button presses that trigger changes to manualkit
class InputListener():
    # Path to the Retroarch config for finding hotkeys
    RETROARCH_CONFIG_PATH = Path('/opt/retropie/configs/all/retroarch.cfg')

    def __init__(self,
        repeat_delay: float = 0.25,
        repeat_interval: float = 0.01,
        repeat_turbo_wait: float = 5.0,
        repeat_turbo_skip: int = 2,
    ) -> None:
        self.repeat_delay = float(repeat_delay)
        self.repeat_interval = float(repeat_interval)
        self.repeat_turbo_wait = float(repeat_turbo_wait)
        self.repeat_turbo_skip = int(repeat_turbo_skip)

        # Defaults
        self.devices = []
        self.handlers = {InputType.KEYBOARD: [], InputType.JOYSTICK: []}
        self.grabbed = False
        self.retroarch_config = self._read_retroarch_config(self.RETROARCH_CONFIG_PATH)

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

        autoconfig_path = self._find_config_for_device(dev_device)
        if autoconfig_path:
            # Treat it like a joystick
            device_config = self._read_retroarch_config(autoconfig_path)
            input_type = InputType.JOYSTICK
            hotkey_config = 'input_enable_hotkey_btn'
            btn_prefix = 'input_'
            btn_suffix = '_btn'
        elif self._is_keyboard_device(dev_device):
            # Treat it like a keyboard
            device_config = self.retroarch_config
            input_type = InputType.KEYBOARD
            hotkey_config = 'input_enable_hotkey'
            btn_prefix = 'input_player1_'
            btn_suffix = ''
        else:
            # Not a keyboard or known joystick -- abort
            logging.debug(f'Skipping device: {path} ({dev_device.name})')
            return

        input_device = self.create_input_device(dev_device, input_type, hotkey=device_config.get(hotkey_config))

        # Bind handlers
        for handler in self.handlers[input_type]:
            if handler.retroarch:
                input_code = device_config.get(f'{btn_prefix}{handler.btn_name}{btn_suffix}')
            else:
                input_code = handler.btn_name

            if input_code:
                input_device.on(input_code, handler.callback, grabbed=handler.grabbed, hotkey=handler.hotkey, on_key_down=handler.on_key_down, repeat=handler.repeat)

        # Start listening for events
        self.devices.append(input_device)
        input_device.start_read(self.event_loop)

        # Sometimes devices are added while manualkit is running.  In that
        # case, we immediately grab control of the input so that everything
        # is redirected to this process.
        if self.grabbed:
            input_device.grab()

    # Executes a callback when the given buton is detected on the input type (keyboard / joystick)
    def on(self,
        input_type: InputType,
        btn_name: str,
        callback: Callable,
        grabbed: bool = True,
        hotkey: bool = False,
        retroarch: bool = True,
        on_key_down: bool = True,
        repeat: bool = True,
    ):
        self.handlers[input_type].append(Handler(btn_name, callback, grabbed, hotkey, retroarch, on_key_down, repeat))

    # Creates a new input device with default configurations and the given overrides
    def create_input_device(self, *args, **kwargs) -> InputDevice:
        return InputDevice(
            *args,
            repeat_delay=self.repeat_delay,
            repeat_interval=self.repeat_interval,
            repeat_turbo_wait=self.repeat_turbo_wait,
            **kwargs,
        )

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
    # This is intended to allow manualkit to sync up with the system
    # when a new controller has been configured.
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

    # Looks up the autoconfiguration file for the given device
    def _find_config_for_device(self, device: evdev.InputDevice) -> Path:
        # Generate SDL GUID
        device_id = '%02x%02x0000%02x%02x0000%02x%02x0000%02x%02x0000' % (
            device.info.bustype & 0xFF, device.info.bustype >> 8,
            device.info.vendor & 0xFF, device.info.vendor >> 8,
            device.info.product & 0xFF, device.info.product >> 8,
            device.info.version & 0xFF, device.info.version >> 8,
        )

        autoconfig_path = Path('/opt/retropie/configs/all/retroarch/autoconfig')

        # Prioritize a matching named configuration before we attempt to look up
        # the device id in other configurations
        cfg_paths = [autoconfig_path.join(f'{device.name}.cfg')] + sorted(autoconfig_path.iterdir())
        for cfg_path in cfg_paths:
            if cfg_path.exists() and device_id in cfg_path.read_text():
                return cfg_ath

    # Makes a best-effort attempt to see if the given device is a keyboard
    # 
    # There's no standard way to detect a keyboard, but it's a pretty good
    # bet that the device will report EV_REP as a capability.
    def _is_keyboard_device(self, device: evdev.InputDevice):
        return evdev.ecodes.EV_REP in device.capabilities().get(evdev.ecodes.EV_KEY, [])

    # Handles exceptions in asyncio loops by logging them.  This ensures
    # the event gets consumed.
    def _handle_exception(self, loop, context):
        message = context.get('exception', context['message'])
        logging.error(f'Caught exception: {context} {message}')

    # Reads the retroarch config file at the given path.  This handles the fact that
    # retroarch configurations don't have sections.
    def _read_retroarch_config(self, path: Path) -> dict:
        with path.open() as f:
            content = '[DEFAULT]\n' + f.read()

        config = configparser.ConfigParser(strict=False)
        config.read_string(content)

        # Convert to dictionary and replace excessive quotes
        config_dict = dict(config['DEFAULT'].items())
        for key, value in config_dict.items():
            config_dict[key] = config_dict[key].strip('"')

        return config_dict
