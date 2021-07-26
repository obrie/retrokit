from __future__ import annotations

import psutil
import signal

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

    # Find the currently active emulator process
    @property
    def process(self) -> Optional[psutil.Process]:
        # Find the top-level runcommand script
        all_processes = psutil.process_iter(attrs=['pid', 'cmdline'])
        runcommand_process = next(filter(lambda p: 'runcommand.sh' in ' '.join(p.info['cmdline']), all_processes), None)

        # The emulator will be the last process running
        if runcommand_process:
            return runcommand_process.children(recursive=True)[-1]

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
