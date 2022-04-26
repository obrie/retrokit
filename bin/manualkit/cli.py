#!/usr/bin/python3

import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import configparser
import logging
import signal
from argparse import ArgumentParser
from functools import partial
from pathlib import Path
from threading import RLock
from typing import Callable, Optional

from manualkit.display import Display
from manualkit.input_listener import InputListener, InputType
from manualkit.pdf import PDF
from manualkit.process_watcher import ProcessWatcher

def synchronized(func):
    def _synchronized(self, *args, **kwargs):
         with self.lock:
            return func(self, *args, **kwargs)
    return _synchronized

class ManualKit():
    BINDING_DEFAULTS = {
        'toggle': 'up',
        'up': 'up',
        'down': 'down',
        'left': 'left',
        'right': 'right',
        'next': 'r',
        'prev': 'l',
        'zoom_in': 'r2',
        'zoom_out': 'l2',
        'retroarch': 'true'
    }

    def __init__(self,
        config_path: Optional[str] = None,
        pdf_path: Optional[str] = None,
        supplementary_pdf_path: Optional[str] = None,
        log_level: str = 'INFO',
        pid_to_track: int = None,
    ) -> None:
        self.pdf = None
        self.process_watcher = None
        self.lock = RLock()

        # Read from config
        config = configparser.ConfigParser(strict=False)
        config.read_dict({'pdf': {}, 'display': {}, 'input': {}, 'keyboard': self.BINDING_DEFAULTS, 'joystick': self.BINDING_DEFAULTS})
        if config_path and Path(config_path).exists():
            config.read(config_path)

        # Set up logger
        root = logging.getLogger()
        root.setLevel(getattr(logging, log_level))
        handler = logging.StreamHandler(sys.stdout)
        handler.setLevel(getattr(logging, log_level))
        formatter = logging.Formatter('%(asctime)s - %(message)s')
        handler.setFormatter(formatter)
        root.addHandler(handler)

        # Connect to the display
        self.display = Display(**config['display'])
        self.display.clear()

        # Start listening to inputs
        self.input_listener = InputListener(**config['input'])

        # Start caching the PDF
        self.load(pdf_path, supplementary_pdf_path)

        # Configure joystick handler
        self._add_handlers(InputType.KEYBOARD, config['keyboard'])
        self._add_handlers(InputType.JOYSTICK, config['joystick'])

        # Handle kill signals
        signal.signal(signal.SIGINT, self.exit)
        signal.signal(signal.SIGTERM, self.exit)

        # Track the PID
        self.track_pid(pid_to_track)

        self.input_listener.listen()

    # Loads the given PDFs
    @synchronized
    def load(self, path: str = None, supplementary_path: str = None, prerender: True) -> None:
        # Free up resources from any existing PDF
        if self.pdf:
            if self.pdf.path == self.pdf_path and self.pdf.supplementary_path == self.supplementary_path:
                # Paths haven't changed -- don't do anything
                return
            else:
                # Paths have changed -- clean up existing resources
                self.pdf.close()

        self.pdf = PDF(path,
            width=self.display.width,
            height=self.display.height,
            buffer_width=self.display.buffer_width,
            buffer_height=self.display.buffer_height,
            supplementary_path=supplementary_path,
            **self.config['pdf'],
        )

        # When a new PDF is being loaded, we force manualkit to be hidden
        self.hide()

        if bool(prerender):
            # "Show" performance enhancement -- pre-render the first page so that
            # it shows up as quickly as possible when the user requests it
            self.jump(0)

    # Tracks and coordinates execution with the given PID
    @synchronized
    def track_pid(self, pid: int = None) -> None:
        # Stop watching any existing PID
        if self.process_watcher:
            self.process_watcher.stop()

        if pid:
            self.process_watcher = ProcessWatcher(pid, self._process_ended)
            self.process_watcher.track()
        else:
            self.process_watcher = None

    # Toggles visibility of the manual
    @synchronized
    def toggle(self, turbo: bool = False) -> None:
        # Ignore repeat toggle callbacks
        if turbo:
            return

        if self.display.visible:
            self.hide()
        else:
            self.show()

    # Shows the manual on either the first page or the last page the user left off
    @synchronized
    def show(self) -> None:
        try:
            self.input_listener.grab()
            if self.process_watcher:
                self.process_watcher.suspend()
            self.refresh()
            self.display.show()
        except Exception as e:
            # If there's an error, then we're going to hide ourselves in order
            # to have the best chance at ensuring the screen isn't blocked
            self.hide()
            logging.error(f'Failed to show: {e}')
            raise e

    # Hides the manual
    @synchronized
    def hide(self) -> None:
        self.input_listener.ungrab()
        try:
            if self.display.visible:
                self.display.hide()
                self.display.clear()
        finally:
            # Always make sure the emulator gets resumed regardless of what happens
            if self.process_watcher:
                self.process_watcher.resume()

    # Cleans up the elements / resources on the display
    def exit(self, *args, **kwargs) -> None:
        try:
            # Try to close things gracefully
            self.input_listener.stop()
            self.display.close()
        finally:
            # Always make sure the emulator gets resumed regardless of what happens
            if self.process_watcher:
                self.process_watcher.resume()

            quit()

    # Renders the currently active PDF page
    def refresh(self) -> None:
        self.display.draw(self.pdf.get_page_image())

    # Adds toggle / navigation handlers for the given input type
    def _add_handlers(self, input_type: InputType, config: configparser.SectionProxy) -> None:
        retroarch = (config['retroarch'] == 'true')

        self.input_listener.on(input_type, config['toggle'], self.toggle, retroarch=retroarch, grabbed=False, hotkey=config.get('hotkey', fallback=True))
        self.input_listener.on(input_type, config['up'], partial(self._navigate, self.pdf.move_up, False), retroarch=retroarch)
        self.input_listener.on(input_type, config['down'], partial(self._navigate, self.pdf.move_down, False), retroarch=retroarch)
        self.input_listener.on(input_type, config['left'], partial(self._navigate, self.pdf.move_left, False), retroarch=retroarch)
        self.input_listener.on(input_type, config['right'], partial(self._navigate, self.pdf.move_right, False), retroarch=retroarch)
        self.input_listener.on(input_type, config['next'], partial(self._navigate, self.pdf.next, True), retroarch=retroarch)
        self.input_listener.on(input_type, config['prev'], partial(self._navigate, self.pdf.prev, True), retroarch=retroarch)
        self.input_listener.on(input_type, config['zoom_in'], partial(self._navigate, self.pdf.zoom_in, False), retroarch=retroarch)
        self.input_listener.on(input_type, config['zoom_out'], partial(self._navigate, self.pdf.zoom_out, False), retroarch=retroarch)

    # Calls the given navigation API, optionally including callback arguments
    @synchronized
    def _navigate(self, navigation_api: Callable, include_args: bool, *args) -> None:
        if include_args:
            navigation_api(*args)
        else:
            navigation_api()

        self.refresh()

    # Sends a SIGINT signal to the current process
    def _process_ended(self) -> None:
        self.process_watcher = None
        os.kill(os.getpid(), signal.SIGINT)

def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='config_path', help='INI file containing the configuration', default='/opt/retropie/configs/all/manualkit.conf')
    parser.add_argument('--pdf', dest='pdf_path', help='PDF file to display')
    parser.add_argument('--supplementary-pdf', dest='supplementary_pdf_path', help='Supplementary PDF')
    parser.add_argument('--log-level', dest='log_level', help='Log level', default='INFO', choices=['DEBUG', 'INFO', 'WARN', 'ERROR'])
    parser.add_argument('--track-pid', dest='pid_to_track', help='PID to track to auto-exit', type=int)
    args = parser.parse_args()
    ManualKit(**vars(args)).run()


if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    main()
