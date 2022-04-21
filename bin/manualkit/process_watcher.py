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
        self.process = psutil.Process(pid)
        self.callback = callback

    # Starts tracking the emulator process.  If that process terminates, then the given
    # callback will be invoked.
    def track(self, pid: int, callback: Callable) -> None:
        self.running = True

        thread = threading.Thread(target=self._track_process, args=[callback])
        thread.setDaemon(True)
        thread.start()

    # Stops tracking the current process
    def stop(self) -> None:
        self.running = False

    # Suspends the emulator so that it doesn't continue to run while other
    # information is on-screen
    def suspend(self) -> None:
        if self.process.is_running():
            self.process.send_signal(signal.SIGSTOP)

    # Resumes the emulator so the user can continue to play
    def resume(self) -> None:
        if self.process.is_running():
            self.process.send_signal(signal.SIGCONT)

    # Invokes the given callback when the emulator terminates
    def _track_process(self, callback: Callable) -> None:
        while self.running and self.process.is_running():
            time.sleep(1)

        if self.running:
            psutil.wait_procs([process], callback=callback)
