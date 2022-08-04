#!/usr/bin/env python3

from __future__ import annotations

import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from powerkit.providers import BaseProvider

import configparser
import psutil
import signal
import shutil

from argparse import ArgumentParser
from typing import List, Optional

# This is a modified version of:
# * https://github.com/crcerror/ES-generic-shutdown
# * https://github.com/RetroFlag/retroflag-picase
# 
# It's written only in Python and provides a few additional nice-to-haves.
class PowerKit():
    def __init__(self, config_path: str) -> None:
        # Read user configuration
        self.config = configparser.ConfigParser(strict=False)
        self.config.read_dict({
            'provider': {'id': None},
            'shutdown': {'enabled': True, 'hold_time': 2},
            'reset': {'enabled': True},
        })
        self.config.read(config_path)

        # Identify which power provider we're working with
        self.provider = BaseProvider.from_config(self.config)

        # Add event handler
        if self.config['shutdown']['enabled']:
            self.provider.on('shutdown', self.shutdown)

        if self.config['reset']['enabled']:
            self.provider.on('reset', self.reset)

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
    def run(self):
        self.provider.run()
        signal.pause()

    # Shuts down the computer, either by asking ES to do it or by doing it ourselves
    def shutdown(self):
        self.provider.blink()

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

    # Handles pressing the reset button:
    # * If emulator is running, kill it
    # * If EmulationStation is running, restart it
    # * If neither emulator nor EmulationStation is running, restart the computer
    def reset(self):
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
    parser.add_argument(dest='config_path', help='INI file containing the configuration', default='/opt/retropie/configs/all/powerkit.conf')
    args = parser.parse_args()
    PowerKit(**vars(args)).run()


if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    main()
