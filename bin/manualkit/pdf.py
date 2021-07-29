import numpy
import poppler
import threading

from PIL import Image, ImageOps
from queue import Queue

# Represents a PDF-based manual
class PDF():
    def __init__(self,
        path: str,
        width: int,
        height: int,
        resolution: int = 150,
        concurrency: int = 4,
    ) -> None:
        self.path = path
        self.width = width
        self.height = height
        self.resolution = int(resolution)
        self.concurrency = int(concurrency)
        self.document = poppler.load_from_file(self.path)
        self.page = 0
        self.images = [None for page in range(0, self.document.pages)]

    # Gets the image data for the current page
    @property
    def page_image(self) -> None:
        return self.images[self.page]

    # cache_in_background and caches each page in the document
    def cache_in_background(self) -> None:
        queue = Queue()
        for page in range(self.document.pages):
            queue.put(page)

        for i in range(min(queue.qsize(), self.concurrency)):
            thread = threading.Thread(target=self._cache_pages, args=[queue])
            thread.setDaemon(True)
            thread.start()

    # Moves to the next page or goes back to the beginning if already on the last page
    def next(self) -> None:
        next_page = self.page + 1
        if next_page >= self.document.pages:
            next_page = 0

        self.jump(next_page)

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self) -> None:
        prev_page = self.page - 1
        if prev_page < 0:
            prev_page = self.document.pages - 1

        self.jump(prev_page)

    # Jumps to the given page number
    def jump(self, page) -> None:
        self.page = page

    # Renders and caches the pages from the document
    def _cache_pages(self, pages: Queue) -> None:
        renderer = poppler.PageRenderer()
        renderer.image_format = poppler.image.Image.Format.rgb24

        while not pages.empty():
            page = pages.get_nowait()

            # Nothing left -- finish the thread
            if page is None:
                break

            self.images[page] = self._render_page(page, renderer)

    # Generates a pixel map for the given page 
    def _render_page(self, page_number: int, renderer: poppler.PageRenderer) -> numpy.array:
        # Render the image in Poppler
        page = self.document.create_page(page_number)
        page_image = renderer.render_page(page, self.resolution, self.resolution)

        # Convert to a PIL image
        image = Image.fromarray(numpy.array(page_image.memoryview(), copy=False))

        # Make sure it matches the expected image size
        resized_image = ImageOps.pad(image, (self.width, self.height), color='black')

        return numpy.array(resized_image)
