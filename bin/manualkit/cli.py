#!/usr/bin/python3

import os
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

import configparser
import logging
import signal
from argparse import ArgumentParser
from pathlib import Path
from typing import Optional

from manualkit.display import Display
from manualkit.emulator import Emulator
from manualkit.input_listener import InputListener
from manualkit.pdf import PDF

class ManualKit():
    def __init__(self,
        pdf_path: str,
        config_path: Optional[str] = None,
        log_level: str = 'INFO',
    ) -> None:
        # Read from config
        config = configparser.ConfigParser()
        config.read_dict({'pdf': {}, 'display': {}, 'input': {}})
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

        # Start caching the PDF
        self.pdf = PDF(pdf_path, width=self.display.image_width, height=self.display.image_height, **config['pdf'])
        self.pdf.cache_in_background()

        # Start listening to inputs
        self.input_listener = InputListener(
            on_toggle=self.toggle,
            on_next=self.next,
            on_prev=self.prev,
            **config['input'],
        )

        # Handle kill signals
        signal.signal(signal.SIGINT, self.exit)
        signal.signal(signal.SIGTERM, self.exit)

        self.input_listener.listen()

    # Toggles visibility of the manual
    def toggle(self) -> None:
        if self.display.visible():
            self.hide()
        else:
            self.show()

    # Shows the manual on either the first page or the last page the user left off
    def show(self) -> None:
        Emulator.instance().suspend()
        self.display.show()

        # Render whatever was the last active page
        self.refresh()

    # Hides the manual
    def hide(self) -> None:
        try:
            self.display.hide()
        finally:
            # Always make sure the emulator gets resumed regardless of what happens
            Emulator.instance().resume()

    # Moves to the next page or goes back to the beginning if already on the last page
    def next(self) -> None:
        self.pdf.next()
        self.refresh()

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self) -> None:
        self.pdf.prev()
        self.refresh()

    # Cleans up the elements / resources on the display
    def exit(self, signum, frame) -> None:
        self.display.close()
        self.input_listener.stop()

        quit()

    # Renders the currently active PDF page
    def refresh(self) -> None:
        self.display.draw(self.pdf.page_image)

def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='pdf_path', help='PDF file to display')
    parser.add_argument(dest='config_path', help='INI file containing the configuration', default='/opt/retropie/configs/all/manualkit.conf')
    parser.add_argument('--log-level', dest='log_level', help='Log level', default='INFO', choices=['DEBUG', 'INFO', 'WARN', 'ERROR'])
    args = parser.parse_args()
    ManualKit(**vars(args)).run()


if __name__ == '__main__':
    signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    main()
