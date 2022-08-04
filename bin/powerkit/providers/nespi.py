#!/usr/bin/env python3

from powerkit.providers import BaseProvider

import gpiozero

class Nespi(BaseProvider):
    name = 'nespi'

    # Pin numbers
    POWER_PIN = 3
    RESET_PIN = 2
    LED_PIN = 14
    POWEREN_PIN = 4

    # Starts listening for button presses
    def run(self):
        self.led = gpiozero.LED(self.LED_PIN)
        self.power = gpiozero.LED(self.POWEREN_PIN)

        # Mark pins as being ON
        self.led.on()
        self.power.on()

        power_button = gpiozero.Button(self.POWER_PIN, hold_time=float(self.config['shutdown']['hold_time']))
        power_button.when_pressed = self.shutdown
        power_button.when_released = self.__enable_led

        reset_button = gpiozero.Button(self.RESET_PIN)
        reset_button.when_pressed = self.reset

    # Shuts down the computer, either by asking ES to do it or by doing it ourselves
    def blink(self) -> None:
        self.led.blink(0.2, 0.2)

    # Turns on the LED
    def __enable_led(self) -> None:
        self.led.on()
