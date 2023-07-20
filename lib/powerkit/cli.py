#!/usr/bin/env python3

from __future__ import annotations

import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import powerkit.providers
from powerkit.providers import BaseProvider

import configparser
import logging
import psutil
import signal
import shutil
import time
from datetime import datetime, timedelta

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
            'logging': {'level': 'INFO'},
            'provider': {'id': ''},
            'shutdown': {'enabled': 'true', 'hold_time': '2'},
            'reset': {'enabled': 'true', 'min_process_interval': '5'},
            'hotkey': {'keyboard': 'true', 'joystick': 'true', 'trigger_delay': '2'}
        })
        self.config.read(config_path)

        # Set up logger
        log_level = self.config['logging']['level']
        logging.basicConfig(level=getattr(logging, log_level), format='%(asctime)s - %(message)s', stream=sys.stdout)

        # Identify which power provider we're working with
        self.provider = BaseProvider.from_config(self.config)

        # Add optional hotkey provider
        if not isinstance(self.provider, powerkit.providers.Hotkey):
            self.hotkey_provider = powerkit.providers.Hotkey(self.config)
            self.hotkey_provider.on('maybe_reset', self.track_emulator)
        else:
            self.hotkey_provider = None

        # Add event handler
        if self.config['shutdown'].getboolean('enabled'):
            self.provider.on('shutdown', self.shutdown)

        if self.config['reset'].getboolean('enabled'):
            self.provider.on('reset', self.reset)

            if self.hotkey_provider:
                self.hotkey_provider.on('reset', self.hotkey_reset)

        self.last_reset = None
        self.min_reset_interval = self.config['reset'].getint('min_process_interval', 0)
        self.last_runcommand_process = None

    # Looks up the currently running emulator
    @property
    def runcommand_process(self) -> Optional[psutil.Process]:
        return next(filter(lambda p: 'bash /opt/retropie/supplementary/runcommand/runcommand.sh' in ' '.join(p.info['cmdline']), self._all_processes()), None)

    # Looks up the currently running EmulationStation process
    @property
    def es_process(self) -> Optional[psutil.Process]:
        return next(filter(lambda p: p.info['cmdline'] and p.info['cmdline'][0] == '/opt/retropie/supplementary/emulationstation/emulationstation', self._all_processes()), None)

    # Looks up all currently running processes
    def _all_processes(self) -> List[psutil.Process]:
        return sorted(psutil.process_iter(attrs=['pid', 'cmdline']), key=lambda p: p.create_time(), reverse=True)

    # Starts listening for button presses
    def run(self):
        # Handle kill signals
        signal.signal(signal.SIGINT, self.exit)
        signal.signal(signal.SIGTERM, self.exit)

        # Run primary provider
        self.provider.run()

        # Run secondary, software-based provider
        if self.hotkey_provider:
            self.hotkey_provider.run()

        signal.pause()

    # Shuts down the computer, either by asking ES to do it or by doing it ourselves
    def shutdown(self):
        self.provider.blink()

        es_process = self.es_process
        if es_process:
            logging.info(f'Shutting down runcommand process')

            # Let emulationstation handle the shutdown
            shutdown_path = Path('/tmp/es-shutdown')
            shutdown_path.touch()
            shutil.chown(shutdown_path, user='pi', group='pi')

            try:
                es_process.kill()
                psutil.wait_procs([es_process])
            except psutil.NoSuchProcess:
                # Failed to talk to ES: manually shut down
                logging.error(f'Failed to shutdown EmulationStation; shutting down system')
                os.system('sudo shutdown -h now')
        else:
            logging.info(f'Shutting down system')
            os.system('sudo shutdown -h now')

    # Handles pressing the reset button:
    # * If emulator is running, kill it
    # * If EmulationStation is running, restart it
    # * If neither emulator nor EmulationStation is running, restart the computer
    def reset(self) -> None:
        if self.last_reset and (datetime.utcnow() - self.last_reset) < timedelta(seconds=self.min_reset_interval):
            logging.info(f'Ignoring reset since less than {self.min_reset_interval}s have passed since the last reset')
            return

        self.last_reset = datetime.utcnow()

        runcommand_process = self.runcommand_process
        es_process = self.es_process

        if runcommand_process:
            logging.info(f'Terminating runcommand process')

            # Kill all child processes and wait until we've confirmed they're terminated
            child_processes = runcommand_process.children(recursive=True)
            for child_process in child_processes:
                try:
                    child_process.kill()
                except psutil.NoSuchProcess:
                    pass

            psutil.wait_procs(child_processes)
        elif es_process:
            logging.info(f'Restarting EmulationStation process')

            # Tell ES to restart itself
            restart_path = Path('/tmp/es-restart')
            restart_path.touch()
            shutil.chown(restart_path, user='pi', group='pi')

            try:
                es_process.kill()
                psutil.wait_procs([es_process])
            except psutil.NoSuchProcess:
                # Failed to talk to ES: manually reboot
                logging.error(f'Failed to terminate EmulationStation; rebooting system')
                os.system('sudo reboot')
        else:
            # Restart computer
            logging.info(f'Rebooting system')
            os.system('sudo reboot')

    # Handles pressing the reset hotkey
    def hotkey_reset(self) -> None:
        runcommand_process = self.last_runcommand_process

        if not runcommand_process:
            # No runcommand / emulator running -- follow our standard process
            self.reset()
        else:
            last_reset = datetime.utcnow()

            # In some cases, we're going to want to delay the trigger a few seconds.
            # For example, libretro emulators will handle quitting on their own.
            # Other standalone emulators will do the same as well.
            # 
            # This delay ensures that the emulator is given a chance to quit before
            # we do it ourselves.
            logging.debug(f'Waiting {self.hotkey_provider.trigger_delay}s before terminating runcommand')
            time.sleep(self.hotkey_provider.trigger_delay)

            if runcommand_process.is_running():
                self.reset()

            self.last_reset = last_reset

    # Track whether there's an emulator currently running so that when the hotkey
    # provider runs, we know to terminate the emulator.
    # 
    # This is particularly important in cases where the emulator supports a native
    # hotkey quit command, but doesn't support a quit_press_twice configuration like
    # RetroArch.  We want to track what was running on the first hotkey press.
    def track_emulator(self) -> None:
        self.last_runcommand_process = self.runcommand_process
        logging.debug(f'Tracking last runcommand process as {self.last_runcommand_process}')

    # Cleans up the resources used by the app
    def exit(self, *args, **kwargs) -> None:
        try:
            # Try to close things gracefully
            self.hotkey_provider.stop()
        finally:
            quit()


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='config_path', help='INI file containing the configuration', default='/opt/retropie/configs/all/powerkit.cfg')
    args = {k: v for k, v in vars(parser.parse_args()).items() if v is not None}
    PowerKit(**args).run()


if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    main()
