#!/usr/bin/env python3

from powerkit.providers import BaseProvider

import gpiozero

class GPi(BaseProvider):
    name = 'gpi'

    # Pin numbers
    POWER_PIN = 26
    POWEREN_PIN = 27

    # Starts listening for button presses
    def run(self):
        self.power = gpiozero.LED(self.POWEREN_PIN)

        # Mark pins as being ON
        self.power.on()

        power_button = gpiozero.Button(self.POWER_PIN, hold_time=float(self.config['shutdown']['hold_time']))
        power_button.when_pressed = self.shutdown
