#!/usr/bin/env python3

from powerkit.providers import BaseProvider

import gpiozero
import re
import subprocess
from pathlib import Path

# This is a modified version of:
# * https://github.com/Overbryd/argononed
# 
# Notes about how signals are sent:
# * https://github.com/spapadim/argon1
class Argon1(BaseProvider):
    name = 'argon1'

    # Pin numbers
    POWER_PIN = 4

    # Path to the argone daemon script
    ARGONONED_PATH = Path('/usr/bin/argononed.py')

    # Starts listening for button presses
    def run(self) -> None:
        self.was_held = False

        # Disable power management since it's handled by powerkit
        self._disable_default_signal_handling()

        self.power_button = gpiozero.Button(self.POWER_PIN, pull_up=False, hold_time=0.03)
        self.power_button.when_released = self._button_released
        self.power_button.when_held = self._button_held

    # Disables the default shutdown signal handling built into argon1's daemon.  This
    # is required so that we can modify the behavior of the restart/shutdown signals.
    def _disable_default_signal_handling(self) -> None:
        if not self.ARGONONED_PATH.exists():
            return

        script = self.ARGONONED_PATH.read_text()
        updated_script = re.sub(r"\n\tt1", "\n\t#t1", script)

        if updated_script != script:
            with self.ARGONONED_PATH.open('w') as script_file:
                script_file.write(updated_script)

            # Restart daemon (ignore any errors)
            subprocess.run('systemctl restart argononed', shell=True)

    # A physical hold of 3+ seconds triggers a 30-50ms hold and must force a shutdown
    def _button_held(self) -> None:
        self.was_held = True

    def _button_released(self) -> None:
        if self.was_held:
            self.shutdown()
        else:
            self.reset()

        self.was_held = False
