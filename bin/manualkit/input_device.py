import asyncio
import evdev
import logging
import traceback
from enum import Enum
from evdev.events import KeyEvent
from pathlib import Path

import manualkit.keycodes

from typing import Callable, Optional

# Represents the type of input that we're listening to
class InputType(Enum):
    KEYBOARD = 'keyboard', manualkit.keycodes.retroarch_keyboard
    JOYSTICK = 'joystick', manualkit.keycodes.retroarch_joystick

    def __init__(self, type_name: str, retroarch_codes: dict) -> None:
        self.type_name = type_name
        self.retroarch_codes = retroarch_codes

# Represents an evdev device that we're listening for events from
class InputDevice():
    # List of EV_ABS codes that we actually care about -- everything else can be
    # ignored.
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
        repeat_delay: float,
        repeat_interval: float,
    ) -> None:
        self.dev_device = dev_device

        # Callbacks
        self.on_toggle = on_toggle
        self.on_next = on_next
        self.on_prev = on_prev

        # asyncio tasks
        self.event_reader_task = None
        self.repeater_task = None
        self.repeat_delay = repeat_delay
        self.repeat_interval = repeat_interval

        # Whether to watch for navigation input events (only occurs when
        # inputs have been grabbed to this process)
        self.watch_navigation = False

        # Adjust inputs for configparser issues
        if hotkey:
            hotkey = hotkey.strip('"')
        toggle_input = toggle_input.strip('"')
        next_input = next_input.strip('"')
        prev_input = prev_input.strip('"')

        # Define expected evdev inputs
        retroarch_codes = input_type.retroarch_codes

        self.toggle_inputs = dict((retroarch_codes[toggle_input],))
        if hotkey:
            code, value = retroarch_codes[hotkey]
            self.toggle_inputs[code] = value

        self.next_inputs = dict((retroarch_codes[next_input],))
        self.prev_inputs = dict((retroarch_codes[prev_input],))

        # List codes that might trigger logic
        self.trigger_codes = set(map(lambda name: retroarch_codes[name][0], [toggle_input, next_input, prev_input]))

        # Track which inputs are currently being pressed.  An input is removed
        # when a "up" value is received for the input.
        self.active_inputs = {}

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
            print(event)
            try:
                await self.read_event(event)
            except Exception as e:
                logging.warn(f'Failed to handle event: {e}')
                traceback.print_exc()

    # Tracks the active inputs and triggers any relevant callbacks
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
        if event.code not in self.trigger_codes:
            return

        if self.active_inputs == self.toggle_inputs:
            self.on_toggle()
        elif self.watch_navigation:
            if self.active_inputs == self.next_inputs:
                self.trigger_navigation(self.on_next)
            elif self.active_inputs == self.prev_inputs:
                self.trigger_navigation(self.on_prev)

    # Triggers a navigation callback and starts a new asyncio task in order to
    # simulate a "hold" pattern in which the event is repeated.
    # 
    # This is done in order to handle certain devices (such as joystick) which can
    # hold down a navigation button but don't actually trigger hold events.
    def trigger_navigation(self, callback: Callable) -> None:
        callback()
        self.start_repeater(callback)

    # Starts asynchronously triggering repeat events to simulate "hold" behavior
    # on a key
    def start_repeater(self, callback: Callable) -> None:
        self.repeater_task = self.event_loop.create_task(self.repeat_callback(callback))

    # Repeatedly triggers the given callback based on the configured repeat delay /
    # interval.  This will only stop when the task is manually cancelled.
    async def repeat_callback(self, callback: Callable) -> None:
        await asyncio.sleep(self.repeat_delay)
        while True:
            callback()
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
        self.watch_navigation = True

        try:
            self.dev_device.grab()
        except Exception as e:
            logging.warn(f'Failed to grab device: {self.dev_device.name} ({e})')

    # Releases control of the current device to the rest of the system
    def ungrab(self):
        self.watch_navigation = False

        try:
            self.dev_device.ungrab()
        except Exception as e:
            logging.warn(f'Failed to ungrab device: {self.dev_device.name} ({e})')
