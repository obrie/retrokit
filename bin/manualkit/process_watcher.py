from __future__ import annotations

import logging
import psutil
import signal
import threading
import time

from typing import Optional

# Provides utilities for interacting with another process
class ProcessWatcher():
    def __init__(self,
        pid: int,
        callback: Callable,
        enabled: bool = True,
        suspend: bool = True,
    ) -> None:
        self.parent_process = psutil.Process(pid)
        self.callback = callback
        self.enabled = bool(enabled)
        self.suspend_enabled = bool(suspend)
        self.suspended_process = None

    # Looks up the last process in the tree -- this is the one we want
    # to interactive with
    @property
    def process(self) -> None:
        try:
            children = self.parent_process.children(recursive=True)
            if children:
                return children[-1]
            else:
                return self.parent_process
        except psutil.NoSuchProcess:
            return None

    # Starts tracking the emulator process.  If that process terminates, then the given
    # callback will be invoked.
    def track(self) -> None:
        if not self.enabled:
            return

        self.running = True

        thread = threading.Thread(target=self._track_process, args=[self.callback])
        thread.setDaemon(True)
        thread.start()

    # Stops tracking the current process
    def stop(self) -> None:
        self.running = False

    # Suspends the emulator so that it doesn't continue to run while other
    # information is on-screen
    def suspend(self) -> None:
        if not self.suspend_enabled:
            return

        process = self.process
        if process:
            # Resume any previously suspended process
            self.resume()

            logging.debug(f'Suspending {process}')
            self.suspended_process = process
            self.suspended_process.send_signal(signal.SIGSTOP)

    # Resumes the emulator so the user can continue to play
    def resume(self) -> None:
        if not self.suspend_enabled:
            return

        if self.suspended_process and self.suspended_process.is_running():
            logging.debug(f'Resuming {self.suspended_process}')
            try:
                self.suspended_process.send_signal(signal.SIGCONT)
            except psutil.NoSuchProcess:
                logging.debug(f'Could not resume {self.suspended_process}')

        self.suspended_process = None

    # Invokes the given callback when the emulator terminates
    def _track_process(self, callback: Callable) -> None:
        while self.running and self.process:
            time.sleep(1)

        if self.running:
            callback()
