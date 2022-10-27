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
        power = gpiozero.LED(self.POWEREN_PIN)

        # Disable cleanup.  If we don't do this, then the power pin will be reset
        # to LOW, causing the system power to be cut before the system has safely
        # shut down.
        # 
        # See: https://github.com/gpiozero/gpiozero/issues/707
        power.pin.close = self._close_pin
        power.pin_factory.close = self._close_pin

        # Mark power as on (indicating we are doing a safe shutdown)
        power.on()

        power_button = gpiozero.Button(self.POWER_PIN)
        power_button.when_pressed = self.shutdown

    def _close_pin(self, *args, **kwargs):
        pass
