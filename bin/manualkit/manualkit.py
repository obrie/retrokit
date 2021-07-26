import logging
import os
import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent.parent))

import configparser

from manualkit import Display, Emulator, InputManager, PDF
from pathlib import Path
from typing import Optional

class ManualKit():
    def __init__(self,
        pdf_path: str,
        config_path: Optional[str] = None,
    ) -> None:
        # Read from config
        config = configparser.ConfigParser()
        conifg.read_dict({'pdf': {}, 'display': {}, 'input': {}})
        if config_path and Path(config_path).exists():
            config.read(config_path)

        # Handle kill signals
        signal.signal(signal.SIGINT, self.exit)
        signal.signal(signal.SIGTERM, self.exit)

        self.display = Display(**config['display'])
        self.pdf = PDF(pdf_path, width=self.display.image_width, height=self.display.image_height, **config['pdf'])
        self.pdf.cache_in_background()
        self.emulator = Emulator()
        self.input_manager = InputManager(**config['input'])

    # Renders the first page of the manual on screen
    def show(self) -> None:
        self.emulator.suspend()
        self.display.show()

        # Render whatever was the last active page
        self.render()

    # Hides the manual
    def hide(self) -> None:
        try:
            self.display.hide()
        finally:
            # Always make sure the emulator gets resumed regardless of what happens
            self.emulator.resume()

    # Moves to the next page or goes back to the beginning if already on the last page
    def next(self) -> None:
        self.pdf.next()
        self.render()

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self) -> None:
        self.pdf.prev()
        self.render()

    # Cleans up the elements / resources on the display
    def exit(self) -> None:
        self.display.close()
        quit()

    # Renders the currently active PDF page
    def render(self) -> None:
        self.display.render(self.pdf.page_image)

def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='pdf', help='PDF file to display')
    parser.add_argument('--config', dest='config_path', help='Configuration file to use', default='/opt/retropie/configs/all/manualkit.conf')
    args = parser.parse_args()
    ManualKit(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
