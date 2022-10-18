#!/usr/bin/env python3

from datetime import datetime, timedelta

import devicekit.retroarch as retroarch
from devicekit.input_device import DeviceEvent
from devicekit.input_type import InputType
from devicekit.input_listener import InputListener

from powerkit.providers import BaseProvider

class Hotkey(BaseProvider):
    name = 'hotkey'

    # Maximum number of seconds that can elapse been double presses
    QUIT_TWICE_WINDOW_SECS = 3

    # Starts listening for button presses
    def run(self):
        retroarch_config = retroarch.Config()

        # Keep track of button presses in case we're configured to have to
        # press twice to quit
        self._quit_press_twice = retroarch_config.get('quit_press_twice') == 'true'
        self._last_pressed_by_device = {}
        self.trigger_delay = self.config['hotkey'].getint('trigger_delay', 0)

        keyboard_enabled = self.config['hotkey'].getboolean('keyboard')
        joystick_enabled = self.config['hotkey'].getboolean('joystick')

        # Start listening to keyboard / joystick events
        if keyboard_enabled or joystick_enabled:
            self._listener = InputListener()

            if keyboard_enabled:
                self._listener.on(InputType.KEYBOARD, 'exit_emulator', self._button_pressed, grabbed=False, hotkey=True, on_key_down=True, retroarch=True, repeat=False)

            if joystick_enabled:
                self._listener.on(InputType.JOYSTICK, 'exit_emulator', self._button_pressed, grabbed=False, hotkey=True, on_key_down=True, retroarch=True, repeat=False)

            self._listener.listen()

    # Stops listening to device events
    def stop(self) -> None:
        self._listener.stop()

    def _button_pressed(self, event: DeviceEvent) -> None:
        now = datetime.utcnow()
        device_id = event.device.id
        last_pressed = self._last_pressed_by_device.get(device_id)

        if not self._quit_press_twice:
            # Only requires a single trigger to reset.  We call `maybe_reset` here
            # in order to make sure powerkit is aware of the currently running process.
            self.trigger('maybe_reset')
            self._trigger_reset()
        elif last_pressed and (now - last_pressed) <= timedelta(seconds=self.QUIT_TWICE_WINDOW_SECS):
            # Pressed twice -- go ahead and reset
            # 
            # We don't run `maybe_reset` here because we want to use the process that
            # was tracked by powerkit on the first press
            self._trigger_reset()
        else:
            # Consider this the first press -- track time and the potential for reset
            self._last_pressed_by_device[device_id] = now
            self.trigger('maybe_reset')

    def _trigger_reset(self) -> None:
        self._last_pressed_by_device.clear()
        self.reset()
