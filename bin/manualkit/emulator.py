from __future__ import annotations

import psutil
import signal
import threading

from typing import Optional

# Provides utilities for interacting with the actively running emulator
class Emulator():
    _instance = None

    @classmethod
    def instance(cls) -> Emulator:
        if cls._instance is None:
            cls._instance = cls.__new__(cls)
            cls._instance.__init__()
        return cls._instance

    # Find the top-level runcommand script
    @property
    def runcommand_process(self) -> Optional[psutil.Process]:
        all_processes = psutil.process_iter(attrs=['pid', 'cmdline'])
        return next(filter(lambda p: 'runcommand.sh' in ' '.join(p.info['cmdline']), all_processes), None)

    # Find the currently active emulator process
    @property
    def process(self) -> Optional[psutil.Process]:
        runcommand = self.runcommand_process
        if runcommand:
            # The emulator will be the last process running
            return runcommand.children(recursive=True)[-1]

    # Starts tracking the emulator process.  If that process terminates, then the given
    # callback will be invoked.
    def track(self, callback: Callable) -> None:
        thread = threading.Thread(target=self._track_process, args=[callback])
        thread.setDaemon(True)
        thread.start()

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
        process = self.runcommand_process
        if not process:
            callback()
        else:
            psutil.wait_procs([process], callback=callback)
