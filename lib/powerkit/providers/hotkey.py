#!/usr/bin/env python3

from datetime import datetime, timedelta

import devicekit.retroarch as retroarch
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
        self._press_count = 0
        self._last_pressed = None
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

    def _button_pressed(self, turbo: bool) -> None:
        now = datetime.utcnow()
        self._press_count += 1

        if not self._quit_press_twice:
            # Only requires a single trigger to reset
            self._trigger_reset()
        elif self._last_pressed:
            time_elapsed = (now - self._last_pressed)
            self._last_pressed = now

            if time_elapsed > timedelta(seconds=self.QUIT_TWICE_WINDOW_SECS):
                # It's been more than the allowed interval: reset back to 1 press
                self._press_count = 1
            else:
                # Pressed twice -- go ahead and reset
                self._trigger_reset()
        else:
            self._last_pressed = now

    def _trigger_reset(self) -> None:
        self._press_count = 0
        self._last_pressed = None
        self.reset()
