import asyncio
import evdev
import logging
from enum import Enum
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

        # Whether to watch for navigation input events (only occurs when
        # inputs have been grabbed to this process)
        self.watch_navigation = False

        # Adjust for configparser issues
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
        self.valid_codes = set(map(lambda name: retroarch_codes[name][0], [toggle_input, next_input, prev_input]))

        # Track which inputs are currently being pressed.  An input is removed
        # when a "up" value is received for the input.
        self.active_inputs = {}

    # Interprets events coming from evdev devices to determine if they should
    # change manualkit behavior
    async def read(self) -> None:
        async for event in self.dev_device.async_read_loop():
            try:
                self.handle_event(event)
            except Exception as e:
                logging.warn(f'Failed to handle event: {e}')

    def handle_event(self, event) -> None:
        # High-performance lookup to see if we should run more logic
        if event.type == evdev.ecodes.EV_KEY or (event.type == evdev.ecodes.EV_ABS and event.code in VALID_ABS_CODES):
            if event.value != 0:
                # Key pressed -- only update on non-repeated events
                repeat = event.value == 2
                if not repeat:
                    self.active_inputs[event.code] = event.value

                self.check_inputs(event, repeat)
            else:
                # Key released
                self.active_inputs.pop(event.code)

    # Check the currently active inputs to see if they should trigger an event
    def check_inputs(self, event: evdev.InputEvent, repeat: bool) -> None:
        if event.code not in self.valid_codes:
            return

        if self.active_inputs == self.toggle_inputs:
            if not repeat:
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
