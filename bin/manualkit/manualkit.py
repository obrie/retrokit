import ctypes
import keyboard
import numpy
import os
import poppler
import signal
import socket
import subprocess
import threading
import time

from contextlib import contextmanager
from pathlib import Path
from PIL import Image
from queue import Queue
from typing import Optional

bcm = ctypes.CDLL('/opt/vc/lib/libbcm_host.so')

DISPMANX_FLAGS_ALPHA_FROM_SOURCE = 0
DISPMANX_PROTECTION_NONE = 0
DISPMANX_NO_ROTATE = 0
VC_IMAGE_RGB888 = 5

def c_ints(x):
  """Return a tuple of c_int, converted from a list of Python variables."""
  return (ctypes.c_int * len(x))(*x)

class ManualKit():
    # The type of image we'll be rendering to the screen
    IMAGE_TYPE = VC_IMAGE_RGB888

    def __init__(self,
        pdf_path: str,
        config_path: Optional[str] = None,
        hotkey: str = 'alt',
        concurrency: int = 4,
        layer: int = -1,
    ) -> None:
        self.pdf = poppler.load_from_file(path)
        self.layer = layer
        self.concurrency = concurrency

        if config_path and Path(config_path).exists():


        # Find the emulator pid
        runcommand_pid = subprocess.run('pgrep -f runcommand.sh | sort | tail -n 1', shell=True, check=True, capture_output=True).stdout.decode()
        self.emulator_pid = subprocess.run(f'pstree -T -p {runcommand_pid} | grep -o "([[:digit:]]*)" | grep -o "[[:digit:]]*" | tail -n ', shell=True, check=True, capture_output=True).stdout.decode()

        # Handle kill signals
        signal.signal(signal.SIGINT, self.exit)
        signal.signal(signal.SIGTERM, self.exit)

        self.display_width = 0
        self.display_height = 0
        self._init_display()

        # Choose the next smallest multiple of 16 for width and height
        self.image_width = self._align_down(self.display_width, 16)
        self.image_height = self._align_down(self.display_height, 16)
        self.image_rect = c_ints((0, 0, self.image_width, self.image_height))
        self.pitch = self.image_width * 3
        assert(self.pitch % 32 == 0)

        # Set up rectangles
        self.src_rect = c_ints((0, 0, self.image_width << 16, self.image_height << 16))
        dest_width = int(self.display_height.value * self.image_width / self.image_height)
        self.dest_rect = c_ints((0, 0, dest_width, self.display_height))

        # Load up all the images
        self.page = 0
        self.pages = [None for page in range(0, self.pdf.pages)]
        self._start_caching()

        # Wait for commands
        self._wait_and_listen(Path(socket_path))

    # Set up the resources on the screen
    def show(self) -> None:
        # Suspend emulator
        kill -STOP "$emulator_pid"

        self.image_element = None
        self.image_resource = None
        self._create_buffer()
        self.jump(0)

    def hide(self) -> None:
        try:
            if self.image_element:
                with self._bcm_update() as dispman_update:
                    bcm.vc_dispmanx_element_remove(dispman_update, self.image_element)
        finally:
            os.kill(self.emulator_pid, signal.SIGCONT)

    # 
    def jump(self, page: int) -> None:
        self.page = page
        image = self.pages[page]
        if not image:
            return

        # Write the image data to the displayed resource
        result = bcm.vc_dispmanx_resource_write_data(
            self.image_resource,
            self.IMAGE_TYPE,
            self.pitch,
            image_buffer.ctypes.data,
            ctypes.byref(self.image_rect),
        )

        # Mark it as modified in order to refresh the screen
        with self._bcm_update() as dispman_update:
            bcm.vc_dispmanx_element_modified(
                dispman_update,
                self.image_element,
                ctypes.byref(self.dest_rect),
            )

    # 
    def next(self) -> None:
        next_page = self.page + 1
        if next_page >= self.pdf.pages:
            next_page = 0

        self.jump(next_page)

    # 
    def prev(self) -> None:
        prev_page = self.page - 1
        if prev_page < 0:
            next_page = self.pdf.pages - 1

        self.jump(prev_page)

    # Cleans up the elements / resources on the display
    def exit(self):
        if self.image_resource:
            bcm.vc_dispmanx_resource_delete(self.image_resource)

        if self.dispman_display:
            bcm.vc_dispmanx_display_close(self.dispman_display)

        quit()

    # Initializes the window that we'll draw to
    def _init_display(self):
        bcm.bcm_host_init()

        self.display_width, self.display_height = ctypes.c_int(), ctypes.c_int()

        # Look up the display dimensions
        success = bcm.graphics_get_display_size(0, ctypes.byref(self.display_width), ctypes.byref(self.display_width)) 
        assert success >= 0

        self.dispman_display = bcm.vc_dispmanx_display_open(0) # LCD
        assert self.dispman_display != 0

    # Adjusts the given value by rounding it down to the nearest multiple of :align_to:
    def _align_down(self, value, align_to):
        return value & ~(align_to - 1)

    # Creates the buffer that'll be used to write to
    def _create_buffer(self):
        vc_image_ptr = ctypes.c_uint()

        with self._bcm_update() as dispman_update:
            # Create resource
            self.image_resource = bcm.vc_dispmanx_resource_create(
                self.IMAGE_TYPE,
                self.image_width,
                self.image_height,
                ctypes.byref(vc_image_ptr),
            )
            assert self.image_resource != 0

            # scale width so that aspect ratio is retained with display height - might crop right part of the bg
            alpha = c_ints((DISPMANX_FLAGS_ALPHA_FROM_SOURCE, 255, 0))
            self.image_element = bcm.vc_dispmanx_element_add(
                dispman_update,
                self.dispman_display,
                self.layer,
                ctypes.byref(self.dest_rect),
                self.image_resource,
                ctypes.byref(self.src_rect),
                DISPMANX_PROTECTION_NONE,
                alpha = ctypes.byref(alpha),
                clamp = 0,
                transform = DISPMANX_NO_ROTATE,
            )

            assert(self.image_element != 0)

    # Starts the process for modifying the display
    @contextmanager
    def _bcm_update(self):
        dispman_update = bcm.vc_dispmanx_update_start(10)
        assert dispman_update != 0

        yield dispman_update

        result = bcm.vc_dispmanx_update_submit_sync(dispman_update)
        assert result == 0

    # Renders and caches each page in the PDF
    def _start_caching(self) -> None:
        self.pages_to_cache = list(range(self.pdf.pages))
        threads = []
        for i in range(min(len(self.pages_to_cache), self.concurrency)):
            thread = threading.Thread(target=self._cache_pages)
            thread.setDaemon(True)
            thread.start()

        try:
            # Wait for workers to finish
            for thread in threads:
                thread.join(raise_exception=True)
        except Exception as e:
            # Empty the queue
            with queue.mutex:
                queue.queue.clear()

            # Wait for all workers to finish, ignoring any exceptions
            for thread in threads:
                thread.join()

            raise e

    # Renders and caches the pages from the PDF
    def _cache_pages(self) -> None:
        renderer = poppler.PageRenderer()

        while not self.pages_to_cache.empty():
            page = self.pages_to_cache.get_nowait()

            # Nothing left -- finish the thread
            if not page:
                break

            self.pages[page] = self._render_image(page)

            # If the user was waiting for this page to render, go ahead and
            # jump to it now
            if page == self.page:
                self.jump(page)

    # Generates an Image object 
    def _render_page(self, page_num: int, renderer: poppler.PageRenderer) -> Image:
        page = self.pdf.create_page(page_num)
        page_image = renderer.render_page(page, 150, 150)

        image = Image.frombytes(
            'RGBA',
            (page_image.width, page_image.height),
            page_image.data,
            "raw",
            str(page_image.format),
        )

        if image.size[0] < self.image_width or image.size[1] < self.image_height:
            image = image.resize((self.image_width, self.image_height), Image.BILINEAR)

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
    parser.add_argument('--layer', type=int, dest='layer', help='Dispmanx layer to render to', default=-1)
    args = parser.parse_args()
    ManualKit(**vars(args)).run()


if __name__ == '__main__':
    signal(SIGPIPE, SIG_DFL)
    main()
