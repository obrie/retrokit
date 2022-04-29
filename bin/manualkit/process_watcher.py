from __future__ import annotations

import logging
import psutil
import signal
import threading
import time

from enum import Enum
from typing import Callable, Optional

# Event handlers that can be added
class ProcessEvent(Enum):
    EXIT = 'exit'

# Provides utilities for interacting with another process
class ProcessWatcher():
    def __init__(self,
        pid: int,
        enabled: bool = True,
    ) -> None:
        self.process = psutil.Process(int(pid))
        self.enabled = bool(enabled)
        self.suspended_process = None
        self.handlers = {ProcessEvent.EXIT: []}

    # Executes a callback when the given event occurs
    def on(self, event: ProcessEvent, callback: Callable) -> None:
        self.handlers[event].append(callback)

    # Starts tracking the emulator process.  If that process terminates, then the given
    # callback will be invoked.
    def track(self) -> None:
        if not self.enabled:
            return

        self.running = True
        logging.debug(f'Process watcher tracking: {self.process}')

        thread = threading.Thread(target=self._track_process)
        thread.setDaemon(True)
        thread.start()

    # Stops tracking the current process
    def stop(self) -> None:
        logging.debug('Stopping process watcher')
        self.running = False

    # Suspends the emulator so that it doesn't continue to run while other
    # information is on-screen
    def suspend(self) -> None:
        process = self._last_child_process()
        if process:
            # Resume any previously suspended process
            self.resume()

            logging.debug(f'Suspending {process}')
            self.suspended_process = process
            self.suspended_process.send_signal(signal.SIGSTOP)

    # Resumes the emulator so the user can continue to play
    def resume(self) -> None:
        if self.suspended_process and self.suspended_process.is_running():
            logging.debug(f'Resuming {self.suspended_process}')
            try:
                self.suspended_process.send_signal(signal.SIGCONT)
            except psutil.NoSuchProcess:
                logging.debug(f'Could not resume {self.suspended_process}')

        self.suspended_process = None

    # Finds the last child launched by the configured process
    def _last_child_process(self) -> Optional[psutil.Process]:
        try:
            children = self.process.children(recursive=True)
            if children:
                return children[-1]
            else:
                return self.process
        except psutil.NoSuchProcess:
            return None

    # Tracks the lifetime of the configured process
    def _track_process(self) -> None:
        while self.running and self.process.is_running():
            time.sleep(1)

        if self.running:
            # Invoke callbacks
            for handler in self.handlers[ProcessEvent.EXIT]:
                handler()
