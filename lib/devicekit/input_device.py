import asyncio
import evdev
import logging
import traceback
from datetime import datetime, timedelta
from evdev.events import KeyEvent
from pathlib import Path

from typing import Callable, NamedTuple, Optional, Union

from devicekit.input_type import InputType

# Represents a callback to invoke when a given code is encountered
class Handler(NamedTuple):
    input_filter: dict
    callback: Callable
    grabbed: bool
    event_type: KeyEvent
    repeat: bool

    # List of EV_ABS codes that we actually care about -- everything else can be
    # ignored.
    VALID_ABS_CODES = {evdev.ecodes.ABS_HAT0X, evdev.ecodes.ABS_HAT0Y}

    # Whether this input event can result in a handler callback:
    # * Ignore hold events
    # * Ignore non-keyboard/unhandled abs events
    @classmethod
    def is_callable_event(cls, event: evdev.InputEvent)-> bool:
        return abs(event.value) != KeyEvent.key_hold and (event.type == evdev.ecodes.EV_KEY or (event.type == evdev.ecodes.EV_ABS and event.code in cls.VALID_ABS_CODES))

    # Whether this handler matches the current state of the input
    def match(self, event: evdev.InputEvent, grabbed: bool) -> bool:
        return (not self.grabbed or grabbed) and self.event_type == abs(event.value)

# Represents an evdev device that we're listening for events from
class InputDevice():
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

        # Handler configuration
        self.hotkey = hotkey
        self.handlers = {}

        # asyncio tasks
        self.event_loop = None
        self.event_reader_task = None

        # Repeater configuration
        self.repeaters = []
        self.repeat_delay = repeat_delay
        self.repeat_interval = repeat_interval
        self.repeat_turbo_wait = timedelta(seconds=repeat_turbo_wait)

        # Track which inputs are currently being pressed.  An input is removed
        # when a "up" value is received for the input.
        self.active_inputs = {}
        self.last_active_inputs = {}
        self.grabbed = False

    # Executes a callback when the given input code is detected on this device
    def on(self,
        # The retroarch input code to listen for
        input_code: str,
        # The callback to execute when the event is triggered
        callback: Callable,
        # Run only when the hotkey is also pressed?
        hotkey: Union[bool, str] = False,
        # Run only when inputs for this device have been "grabbed" by the current process?
        grabbed: bool = True,
        # Run only when the key is pressed? (vs. released)
        on_key_down: bool = True,
        # Trigger repeatedly according to the configured repeat interval?
        repeat: bool = True,
    ) -> None:
        input_codes = [input_code]
        if isinstance(hotkey, str):
            if hotkey != 'false':
                input_codes.append(hotkey)
        elif hotkey and self.hotkey:
            input_codes.append(self.hotkey)

        if on_key_down:
            event_type = KeyEvent.key_down
        else:
            event_type = KeyEvent.key_up
            # Ignore the "repeat" config
            repeat = False

        # Translate retroarch code => evdev code
        evdev_codes = self.input_type.retroarch_codes(self.dev_device)
        input_filter = dict(map(lambda code: evdev_codes[code], input_codes))

        # Track the handler
        handler_key = frozenset(input_filter.items())
        self.handlers[handler_key] = self.handlers.get(handler_key, []) + [Handler(input_filter, callback, grabbed, event_type, repeat)]

    # The path on the filesystem representing this device (/dev/input/eventX)
    @property
    def path(self) -> str:
        return self.dev_device.path

    # Grabs control of the current device so that events only get routed to this process
    def grab(self):
        if self.grabbed:
            return

        self.grabbed = True

        try:
            self.dev_device.grab()
        except Exception as e:
            logging.warn(f'Failed to grab device: {self.dev_device.name} ({e})')

    # Releases control of the current device to the rest of the system
    def ungrab(self):
        if not self.grabbed:
            return

        self.grabbed = False

        try:
            self.dev_device.ungrab()
        except Exception as e:
            logging.warn(f'Failed to ungrab device: {self.dev_device.name} ({e})')

    # Starts asynchronously reading events from the device
    def start_read(self, event_loop: asyncio.AbstractEventLoop) -> None:
        self.event_loop = event_loop

        if event_loop.is_running():
            self.event_reader_task = asyncio.run_coroutine_threadsafe(self._read_events(), event_loop)
        else:
            self.event_reader_task = event_loop.create_task(self._read_events())

    # Stops reading events from the device
    def stop_read(self) -> None:
        if self.event_reader_task:
            self.event_reader_task.cancel()
            self.event_reader_task = None

        if self.repeaters:
            for repeater in self.repeaters:
                repeater.cancel()
                repeater = None

    # Interprets events coming from evdev devices to determine if they should
    # change devicekit behavior
    async def _read_events(self) -> None:
        async for event in self.dev_device.async_read_loop():
            try:
                await self._read_event(event)
            except Exception as e:
                logging.warn(f'Failed to handle event: {e}')
                traceback.print_exc()

    # Tracks the active inputs and triggers any relevant handlers
    async def _read_event(self, event: evdev.InputEvent) -> None:
        if Handler.is_callable_event(event):
            # Wait for repeater to officially stop
            if self.repeaters:
                for repeater in self.repeaters:
                    await repeater.stop()
                self.repeaters.clear()

            if abs(event.value) == KeyEvent.key_down:
                # Key pressed
                self.active_inputs[event.code] = event.value
                self.last_active_inputs = self.active_inputs.copy()

                # Check what's currently pressed down
                self._check_inputs(event, self.active_inputs)
            else:
                # Key released
                self.active_inputs.pop(event.code)
                if not self.active_inputs:
                    self._check_inputs(event, self.last_active_inputs)


    # Check the currently active inputs to see if they should trigger an event
    def _check_inputs(self, event: evdev.InputEvent, active_inputs: dict) -> None:
        matched_handlers = self.handlers.get(frozenset(active_inputs.items()))
        if not matched_handlers:
            return

        for handler in matched_handlers:
            if handler and handler.match(event, self.grabbed):
                handler.callback(False)

                # Run a repeater in order to simulate a "hold" pattern
                # 
                # This is done in order to handle certain devices (such as joystick) which can
                # hold down a navigation button but don't actually trigger hold events.
                if handler.repeat:
                    repeater = InputRepeater(handler.callback, self.repeat_delay, self.repeat_interval, self.repeat_turbo_wait)
                    repeater.start(self.event_loop)
                    self.repeaters.append(repeater)


# Encapsulates the logic for repeat callbacks when they're being held down
class InputRepeater:
    def __init__(self,
        callback: Callable,
        repeat_delay: float,
        repeat_interval: float,
        repeat_turbo_wait: float,
    ) -> None:
        self.callback = callback
        self.repeat_delay = repeat_delay
        self.repeat_interval = repeat_interval
        self.repeat_turbo_wait = repeat_turbo_wait

    # Starts asynchronously triggering repeat events to simulate "hold" behavior
    # on a key
    def start(self, event_loop) -> None:
        self._task = event_loop.create_task(self._repeat_callback(self.callback))

    # Repeatedly triggers the given callback based on the configured repeat delay /
    # interval.  This will only stop when the task is manually cancelled.
    async def _repeat_callback(self, callback: Callable) -> None:
        start_time = datetime.utcnow()
        turbo = False

        await asyncio.sleep(self.repeat_delay)
        while True:
            if (datetime.utcnow() - start_time) >= self.repeat_turbo_wait:
                turbo = True

            callback(turbo)
            await asyncio.sleep(self.repeat_interval)

    # Stops any asynchronous task running to repeat events.  This ensures the tasks
    # are confirmed as stopped before returning.
    async def stop(self) -> None:
        if self._task:
            self.cancel()

            try:
                await self._task
            except asyncio.CancelledError as e:
                pass
            finally:
                self._task = None

    # Immediately cancels the asynchronous task and returns without waiting for
    # the task to be confirmed as stopped
    def cancel(self) -> None:
        if self._task:
            self._task.cancel()
