#!/usr/bin/env python3

from __future__ import annotations

import gpiozero
import os
import psutil
import signal
import shutil
import subprocess

from pathlib import Path
from typing import List, Optional

# This is a modified version of:
# * https://github.com/crcerror/ES-generic-shutdown
# * https://github.com/RetroFlag/retroflag-picase
# 
# It's written only in Python and provides a few additional nice-to-haves.
class SafeShutdown():
    # Pin numbers
    POWER_PIN = 3
    RESET_PIN = 2
    LED_PIN = 14
    POWEREN_PIN = 4

    # Number of seconds to wait while the button is being pressed before we decide
    # that a shut down was intended
    HOLD_SECONDS = 1

    def __init__(self,
        config_path: Optional[str] = None,
    ) -> None:
        self.led = gpiozero.LED(LED_PIN)
        self.power = gpiozero.LED(POWEREN_PIN)

    # Looks up the currently running emulator
    @property
    def runcommand_process(self) -> Optional[psutil.Process]:
        all_processes = psutil.process_iter(attrs=['pid', 'cmdline'])
        return next(filter(lambda p: 'runcommand.sh' in ' '.join(p.info['cmdline']), self._all_processes()), None)

    # Looks up the currently running EmulationStation process
    @property
    def es_process(self) -> Optional[psutil.Process]:
        return next(filter(lambda p: p.info['cmdline'] and p.info['cmdline'][0] == '/opt/retropie/supplementary/emulationstation/emulationstation', self._all_processes()), None)

    # Looks up all currently running processes
    def _all_processes(self) -> List[psutil.Process]:
        return sorted(psutil.process_iter(attrs=['pid', 'cmdline']), key=lambda p: p.create_time(), reverse=True)

    # Starts listening for button presses
    def run():
        # Mark pins as being ON
        self.led.on()
        self.power.on()

        power_button = gpiozero.Button(POWER_PIN, hold_time=HOLD_SECONDS)
        power_button.when_pressed = self.shutdown
        power_button.when_released = self.enable_led

        reset_button = gpiozero.Button(RESET_PIN)
        reset_button.when_pressed = self.reset

        signal.pause()

    # Shuts down the computer, either by asking ES to do it or by doing it ourselves
    def shutdown():
        self.led.blink(0.2, 0.2)

        es_process = self.es_process
        if es_process:
            restart_path = Path('/tmp/es-shutdown')
            restart_path.touch()
            shutil.chown(restart_path, user='pi', group='pi')

            try:
                es_process.kill()
                psutil.wait_procs([es_process])
            except psutil.NoSuchProcess:
                # Failed to talk to ES: manually shut down
                os.system('sudo shutdown -h now')
        else:
            os.system('sudo shutdown -h now')

    # Turns on the LED
    def enable_led():
        self.led.on()

    # Handles pressing the reset button:
    # * If emulator is running, kill it
    # * If EmulationStation is running, restart it
    # * If neither emulator nor EmulationStation is running, restart the computer
    def reset():
        runcommand_process = self.runcommand_process
        es_process = self.es_process

        if runcommand_process:
            # Kill all child processes and wait until we've confirmed they're terminated
            child_processes = runcommand_process.children(recursive=True)
            for child_process in child_processes:
                try:
                    child_process.kill()
                except psutil.NoSuchProcess:
                    pass

            psutil.wait_procs(child_processes)
        elif es_process:
            # Tell ES to restart itself
            restart_path = Path('/tmp/es-restart')
            restart_path.touch()
            shutil.chown(restart_path, user='pi', group='pi')

            try:
                es_process.kill()
                psutil.wait_procs([es_process])
            except psutil.NoSuchProcess:
                # Failed to talk to ES: manually reboot
                os.system('sudo reboot')
        else:
            # Restart computer
            os.system('sudo reboot')


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='config_path', help='INI file containing the configuration', default='/opt/retropie/configs/all/safe_shutdown.conf')
    args = parser.parse_args()
    SafeShutdown(**vars(args)).run()


if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    main()
