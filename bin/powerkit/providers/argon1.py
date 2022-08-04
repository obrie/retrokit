#!/usr/bin/env python3

from powerkit.providers import BaseProvider

import gpiozero

# This is a modified version of:
# * https://github.com/Overbryd/argononed
# 
# Notes about how signals are sent:
# * https://github.com/spapadim/argon1
class Argon1(BaseProvider):
    name = 'argon1'

    # Pin numbers
    POWER_PIN = 4

    # Starts listening for button presses
    def run(self) -> None:
        self.was_held = False

        self.power_button = gpiozero.Button(self.POWER_PIN, pull_up=False, hold_time=0.03)
        self.power_button.when_released = self.__button_released
        self.power_button.when_held = self.__button_held

    # A physical hold of 3+ seconds triggers a 30-50ms hold and must force a shutdown
    def __button_held(self) -> None:
        self.was_held = True

    def __button_released(self) -> None:
        if self.was_held:
            self.shutdown()
        else:
            self.reset()

        self.was_held = False
