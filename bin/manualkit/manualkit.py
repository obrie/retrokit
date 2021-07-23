import configparser
import ctypes
import ctypes.util
import keyboard
import numpy
import poppler
import psutil
import signal
import socket
import subprocess
import threading
import time

from contextlib import contextmanager
from pathlib import Path
from PIL import Image
from queue import Queue
from typing import Generator, Optional, Tuple

# DispmanX C API
bcm = ctypes.CDLL(ctypes.util.find_library('bcm_host'))

class ManualKit():
    # Alpha blending (no transparency)
    DISPMANX_FLAGS_ALPHA_FROM_SOURCE = 0

    # No copyright protection
    DISPMANX_PROTECTION_NONE = 0

    # No image rotation
    DISPMANX_NO_ROTATE = 0

    # Output format (i.e. RGB24)
    VC_IMAGE_RGB888 = 5

    # The type of image we'll be rendering to the screen
    IMAGE_TYPE = VC_IMAGE_RGB888

    def __init__(self,
        pdf_path: str,
        config_path: Optional[str] = None,
        hotkey: str = 'alt',
        concurrency: int = 4,
        resolution: int = 150,
        layer: int = -1,
    ) -> None:
        # Read from config
        config = configparser.ConfigParser()
        if config_path and Path(config_path).exists():
            config.read(config_path)
        self.hotkey = config.get('manualkit', 'hotkey', fallback=hotkey)
        self.concurrency = int(config.get('manualkit', 'concurrency', fallback=concurrency))
        self.resolution = int(config.get('manualkit', 'resolution', fallback=resolution))
        self.layer = int(config.get('manualkit', 'layer', fallback=layer))

        # Handle kill signals
        signal.signal(signal.SIGINT, self.exit)
        signal.signal(signal.SIGTERM, self.exit)

        # Connect to the display
        self.dispman_display = None
        self.display_width = None
        self.display_height = None
        self.image_element = None
        self.image_resource = None
        self._init_display()

        # Set up target image dimensions
        self.image_width = self._align_down(self.display_width, 16)
        self.image_height = self._align_down(self.display_height, 16)
        self.image_rect = self._c_ints((0, 0, self.image_width, self.image_height))
        self.pitch = self.image_width * 3
        assert self.pitch % 32 == 0

        # Set up display coordinates
        self.src_rect = self._c_ints((0, 0, self.image_width << 16, self.image_height << 16))
        dest_width = int(self.display_height * self.image_width / self.image_height)
        self.dest_rect = self._c_ints((0, 0, dest_width, self.display_height))

        # Render and cache the pages from the pdf
        self.pdf = poppler.load_from_file(pdf_path)
        self.current_page = 0
        self.pages = [None for page in range(0, self.pdf.pages)]
        self._cache_in_background()

        # Wait for commands
        self._wait_and_listen(Path(socket_path))

    # Gets the process for the current emulator that's running so that we can
    # suspend it when showing a manual
    @property
    def emulator_process(self) -> psutil.Process:
        # Find the top-level runcommand
        all_processes = psutil.process_iter(attrs=['pid', 'cmdline'])
        runcommand_process = next(filter(lambda p: 'runcommand.sh' in ' '.join(p.info['cmdline']), all_processes))

        # The emulator will be the last process running
        return runcommand_process.children(recursive=True)[-1]

    # Renders the first page of the manual on screen
    def show(self) -> None:
        # Suspend emulator
        self.suspend_emulator()

        # Create the area for us to draw on
        vc_image_ptr = ctypes.c_uint()
        with self._update_display() as dispman_update:
            # Create resource
            self.image_resource = bcm.vc_dispmanx_resource_create(
                self.IMAGE_TYPE,
                self.image_width,
                self.image_height,
                ctypes.byref(vc_image_ptr),
            )
            assert self.image_resource != 0

            alpha = self._c_ints((DISPMANX_FLAGS_ALPHA_FROM_SOURCE, 255, 0))
            self.image_element = bcm.vc_dispmanx_element_add(
                dispman_update,
                self.dispman_display,
                self.layer,
                ctypes.byref(self.dest_rect),
                self.image_resource,
                ctypes.byref(self.src_rect),
                DISPMANX_PROTECTION_NONE,
                ctypes.byref(alpha), # alpha
                0, # clamp
                DISPMANX_NO_ROTATE, # transform
            )
            assert self.image_element != 0

        # Show the first page
        self.jump(0)

    # Hides the manual
    def hide(self) -> None:
        try:
            # Remove the image we've been drawing on screen
            if self.image_element:
                with self._update_display() as dispman_update:
                    bcm.vc_dispmanx_element_remove(dispman_update, self.image_element)
                self.image_element = None
        finally:
            # Always make sure the emulator gets resumed regardless of what happens
            self.resume_emulator()

    # Jumps to the given page in the manual
    def jump(self, page: int) -> None:
        self.current_page = page
        image_data = self.pages[page]
        if not image_data:
            return

        # Write the image data to the displayed resource
        result = bcm.vc_dispmanx_resource_write_data(
            self.image_resource,
            self.IMAGE_TYPE,
            self.pitch,
            image_data.ctypes.data,
            ctypes.byref(self.image_rect),
        )

        # Mark it as modified in order to refresh the screen
        with self._update_display() as dispman_update:
            bcm.vc_dispmanx_element_modified(
                dispman_update,
                self.image_element,
                ctypes.byref(self.dest_rect),
            )

    # Moves to the next page or goes back to the beginning if already on the last page
    def next(self) -> None:
        next_page = self.current_page + 1
        if next_page >= self.pdf.pages:
            next_page = 0

        self.jump(next_page)

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self) -> None:
        prev_page = self.current_page - 1
        if prev_page < 0:
            next_page = self.pdf.pages - 1

        self.jump(prev_page)

    # Cleans up the elements / resources on the display
    def exit(self) -> None:
        if self.image_resource:
            bcm.vc_dispmanx_resource_delete(self.image_resource)

        if self.dispman_display:
            bcm.vc_dispmanx_display_close(self.dispman_display)

        quit()

    # Suspends the currently running emulator so that it doesn't continue to run
    # while the manual is being displayed
    def suspend_emulator(self) -> None:
        process = self.emulator_process
        if process:
            process.send_signal(signal.SIGSTOP)

    # Resumes the currently running emulator so the user can continue to play
    def resume_emulator(self) -> None:
        process = self.emulator_process
        if process:
            process.send_signal(signal.SIGCONT)

    # Initializes the window that we'll draw to
    def _init_display(self) -> None:
        bcm.bcm_host_init()

        display_width = ctypes.c_int()
        display_height = ctypes.c_int()

        # Look up the display dimensions
        success = bcm.graphics_get_display_size(0, ctypes.byref(display_width), ctypes.byref(display_height)) 
        assert success >= 0

        self.display_width = display_width.value
        self.display_height = display_height.value

        self.dispman_display = bcm.vc_dispmanx_display_open(0) # LCD
        assert self.dispman_display != 0

    # Adjusts the given value by rounding it down to the nearest multiple of :align_to:
    def _align_down(self, value: int, align_to: int) -> int:
        return value & ~(align_to - 1)

    # Generates a tuple of c_int objects
    def _c_ints(self, values: Tuple[int]) -> None:
        return (ctypes.c_int * len(values))(*values)

    # Starts the process for modifying the display
    @contextmanager
    def _update_display(self) -> Generator[ctypes.c_int, None, None]:
        dispman_update = bcm.vc_dispmanx_update_start(10)
        assert dispman_update != 0

        yield dispman_update

        result = bcm.vc_dispmanx_update_submit_sync(dispman_update)
        assert result == 0

    # Renders and caches each page in the PDF
    def _cache_in_background(self) -> None:
        queue = Queue()
        for page in range(self.pdf.pages):
            queue.put(page)

        for i in range(min(queue.qsize(), self.concurrency)):
            thread = threading.Thread(target=self._cache_pages, args=[queue])
            thread.setDaemon(True)
            thread.start()

    # Renders and caches the pages from the PDF
    def _cache_pages(self, queue: Queue) -> None:
        renderer = poppler.PageRenderer()

        while not queue.empty():
            page = queue.get_nowait()

            # Nothing left -- finish the thread
            if page is None:
                break

            self.pages[page] = self._render_page(page, renderer)

    # Generates a pixel map for the given page 
    def _render_page(self, page_num: int, renderer: poppler.PageRenderer) -> numpy.array:
        # Render the image in Poppler
        page = self.pdf.create_page(page_num)
        page_image = renderer.render_page(page, self.resolution, self.resolution)

        # Convert to a PIL image
        image = Image.frombytes(
            'RGBA',
            (page_image.width, page_image.height),
            page_image.data,
            "raw",
            str(page_image.format),
        )

        # Make sure it matches the expected image size
        if image.size[0] < self.image_width or image.size[1] < self.image_height:
            image = image.resize((self.image_width, self.image_height), Image.BILINEAR)

        # Make sure it matches the display mode
        if image.mode != 'RGB':
            image = image.convert('RGB')

        return numpy.array(image)

    # Starts listening for keyboard events.  This method will never return.
    def _wait_and_listen(self) -> None:
        keyboard.add_hotkey(self.hotkey + '+m', self.show, suppress=True)
        keyboard.add_hotkey(self.hotkey + '+q', self.hide, suppress=True)
        keyboard.add_hotkey(self.hotkey + '+n', self.next, suppress=True)
        keyboard.add_hotkey(self.hotkey + '+b', self.prev, suppress=True)
        keyboard.wait()


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument(dest='pdf', help='PDF file to display')
    parser.add_argument('--config', dest='config_path', help='Configuration file to use')
    parser.add_argument('--hotkey', dest='hotkey', help='Hotkey to use for listening to events', default='alt')
    parser.add_argument('--concurrency', type=int, dest='concurrency', help='Number of concurrent rendering threads to use', default=4)
    parser.add_argument('--resolution', type=int, dest='resolution', help='Resolution (DPI) of the image to display', default=150)
    parser.add_argument('--layer', type=int, dest='layer', help='Dispmanx layer to render to', default=-1)
    args = parser.parse_args()
    ManualKit(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
