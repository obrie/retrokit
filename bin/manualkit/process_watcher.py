from __future__ import annotations

import psutil
import signal
import threading
import time

from typing import Optional

# Provides utilities for interacting with another process
class ProcessWatcher():
    _instance = None

    def __init__(self, pid: int, callback: Callable) -> None:
        self.parent_process = psutil.Process(pid)
        self.callback = callback

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
        process = self.process
        if process:
            process.send_signal(signal.SIGSTOP)

    # Resumes the emulator so the user can continue to play
    def resume(self) -> None:
        process = self.process
        if process:
            process.send_signal(signal.SIGCONT)

    # Invokes the given callback when the emulator terminates
    def _track_process(self, callback: Callable) -> None:
        while self.running and self.process:
            time.sleep(1)

        if self.running:
            callback()
