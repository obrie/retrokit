from __future__ import annotations

import logging
import os
import threading

from enum import Enum
from pathlib import Path

from manualkit.decorators import synchronized

# Provides server capabilities via a FIFO queue so that manualkit can live in
# the background and, over time, change which PDF is being viewed based on changes
# elsewhere in the system
class Server():
    def __init__(self, fifo_path: str) -> None:
        self.fifo_path = Path(fifo_path)
        self.handlers = {}
        self.lock = threading.Lock()

    # Starts listening for events from the queue.
    def start(self) -> None:
        self.running = True

        self.listener_thread = threading.Thread(target=self.listen)
        self.listener_thread.setDaemon(True)
        self.listener_thread.start()

    # Stop listening for events from the queue.
    # 
    # This will also delete the FIFO queue in order to try to not leave artifacts
    # around on the filesystem.
    @synchronized
    def stop(self) -> None:
        logging.debug('Stopping server')
        self.running = False

        # Remove the fifo file
        self.fifo_path.unlink()

    # Executes a callback when the given event is read from the queue
    def on(self, event: str, callback: Callable) -> None:
        if event not in self.handlers:
            self.handlers[event] = []

        self.handlers[event].append(callback)

    # Reads from the FIFO path, attempting to process all incoming events
    def listen(self) -> None:
        if not self.fifo_path.exists():
            os.mkfifo(self.fifo_path, mode=0o666)

        while self.running:
            # The queue closes when the writer closes, so we need to keep
            # re-opening the file so long as the server is running
            with self.fifo_path.open() as fifo:
                while self.running:
                    try:
                        message = fifo.readline()
                        if len(message) == 0:
                            # Writer has stopped
                            break

                        self._process_message(message)
                    except Exception as e:
                        # Never let an exception stop the server
                        logging.warn(f'Failed to process "{message}": {e}')

                        # Stop reading from the file
                        break

    # Processes a message from the queue
    @synchronized
    def _process_message(self, message: str) -> None:
        event, *args = message.strip().split('\t')
        logging.debug(f'{event} {args}')

        if event in self.handlers:
            # Known event: process it
            for handler in self.handlers[event]:
                handler(*args)
        else:
            logging.warn(f'Unhandled server event: {event}')
