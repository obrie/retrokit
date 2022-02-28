import asyncio
import evdev
import logging
import traceback
from datetime import datetime, timedelta
from enum import Enum
from evdev.events import KeyEvent
from pathlib import Path

import manualkit.keycodes

from typing import Callable, Optional

# Represents the type of input that we're listening to
class InputType(Enum):
    KEYBOARD = 'keyboard', manualkit.keycodes.retroarch_keyboard
    JOYSTICK = 'joystick', manualkit.keycodes.retroarch_joystick

    def __init__(self, type_name: str, retroarch_codes: Callable) -> None:
        self.type_name = type_name
        self.retroarch_codes = retroarch_codes

# Represents a callback to invoke when a given code is encountered
class Handler:
    def __init__(self, input_filter: dict, callback: Callable, grabbed: bool) -> None:
        self.input_filter = input_filter
        self.callback = callback
        self.grabbed = grabbed

# Represents an evdev device that we're listening for events from
# 
# TODO: Can we / should we move from udev to sdl2?
class InputDevice():
    # List of EV_ABS codes that we actually care about -- everything else can be
    # ignored.
    VALID_ABS_CODES = {evdev.ecodes.ABS_HAT0X, evdev.ecodes.ABS_HAT0Y}

    def __init__(self,
        dev_device: evdev.InputDevice,
        input_type: InputType,
        hotkey: Optional[str],
        repeat_delay: float,
        repeat_interval: float,
        repeat_turbo_wait: float,
    ) -> None:
        self.dev_device = dev_device
        self.input_type = input_type

        self.grabbed = False
        self.hotkey = hotkey
        self.handlers = {}

        # asyncio tasks
        self.event_reader_task = None
        self.repeater_task = None
        self.repeat_delay = repeat_delay
        self.repeat_interval = repeat_interval
        self.repeat_turbo_wait = timedelta(seconds=repeat_turbo_wait)

        # Track which inputs are currently being pressed.  An input is removed
        # when a "up" value is received for the input.
        self.active_inputs = {}

    # Executes a callback when the given input code is detected on this device
    def on(self, input_code: str, callback: Callable, hotkey: False, grabbed: bool = True) -> None:
        input_codes = [input_code]
        if isinstance(hotkey, str):
            if hotkey != 'false':
                input_codes.append(hotkey)
        elif hotkey and self.hotkey:
            input_codes.append(self.hotkey)

        # Translate retroarch code => evdev code
        evdev_codes = self.input_type.retroarch_codes(self.dev_device)
        input_filter = dict(map(lambda code: evdev_codes[code], input_codes))

        # Track the handler
        self.handlers[frozenset(input_filter)] = Handler(input_filter, callback, grabbed)

    # The path on the filesystem representing this device (/dev/input/eventX)
    @property
    def path(self) -> str:
        return self.dev_device.path

    # Starts asynchronously reading events from the device
    def start_read(self, event_loop: asyncio.AbstractEventLoop) -> None:
        self.event_loop = event_loop
        self.event_reader_task = event_loop.create_task(self.read_events())

    # Stops reading events from the device
    def stop_read(self) -> None:
        if self.event_reader_task:
            self.event_reader_task.cancel()
            self.event_reader_task = None

        if self.repeater_task:
            self.repeater_task.cancel()
            self.repeater_task = None

    # Interprets events coming from evdev devices to determine if they should
    # change manualkit behavior
    async def read_events(self) -> None:
        async for event in self.dev_device.async_read_loop():
            try:
                await self.read_event(event)
            except Exception as e:
                logging.warn(f'Failed to handle event: {e}')
                traceback.print_exc()

    # Tracks the active inputs and triggers any relevant handlers
    async def read_event(self, event: evdev.InputEvent) -> None:
        value = abs(event.value)

        # High-performance lookup to see if we should run more logic
        if value != KeyEvent.key_hold and (event.type == evdev.ecodes.EV_KEY or (event.type == evdev.ecodes.EV_ABS and event.code in self.VALID_ABS_CODES)):
            # Wait for repeater to officially stop
            await self.stop_repeater()

            if value == KeyEvent.key_down:
                # Key pressed
                self.active_inputs[event.code] = event.value
                self.check_inputs(event)
            else:
                # Key released
                self.active_inputs.pop(event.code)

    # Check the currently active inputs to see if they should trigger an event
    def check_inputs(self, event: evdev.InputEvent) -> None:
        handler = self.handlers.get(frozenset(self.active_inputs))
        if handler and (not handler.grabbed or self.grabbed):
            self.trigger(handler.callback)

    # Triggers a callback and starts a new asyncio task in order to simulate a
    # "hold" pattern in which the event is repeated.
    # 
    # This is done in order to handle certain devices (such as joystick) which can
    # hold down a navigation button but don't actually trigger hold events.
    def trigger(self, callback: Callable) -> None:
        callback(False)
        self.start_repeater(callback)

    # Starts asynchronously triggering repeat events to simulate "hold" behavior
    # on a key
    def start_repeater(self, callback: Callable) -> None:
        self.repeater_task = self.event_loop.create_task(self.repeat_callback(callback))

    # Repeatedly triggers the given callback based on the configured repeat delay /
    # interval.  This will only stop when the task is manually cancelled.
    async def repeat_callback(self, callback: Callable) -> None:
        start_time = datetime.utcnow()
        turbo = False

        await asyncio.sleep(self.repeat_delay)
        while True:
            if (datetime.utcnow() - start_time) >= self.repeat_turbo_wait:
                turbo = True

            callback(turbo)
            await asyncio.sleep(self.repeat_interval)

    # Stops any asynchronous task running to repeat events
    async def stop_repeater(self) -> None:
        if self.repeater_task:
            self.repeater_task.cancel()

            try:
                await self.repeater_task
            except asyncio.CancelledError as e:
                pass
            finally:
                self.repeater_task = None

    # Grabs control of the current device so that events only get routed to this process
    def grab(self):
        self.grabbed = True

        try:
            self.dev_device.grab()
        except Exception as e:
            logging.warn(f'Failed to grab device: {self.dev_device.name} ({e})')

    # Releases control of the current device to the rest of the system
    def ungrab(self):
        self.grabbed = False

        try:
            self.dev_device.ungrab()
        except Exception as e:
            logging.warn(f'Failed to ungrab device: {self.dev_device.name} ({e})')
