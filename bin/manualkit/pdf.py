import numpy
import poppler
import threading

from PIL import Image
from queue import Queue

# Represents a PDF-based manual
class PDF():
    def __init__(self, path: str, width: int, height: int, concurrency: int = 4) -> None:
        self.path = path
        self.width = width
        self.height = height
        self.concurrency = concurrency
        self.document = poppler.load_from_file(self.path)
        self.page = 0
        self.images = [None for page in range(0, self.document.pages)]

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
            next_page = self.document.pages - 1

        self.jump(prev_page)

    # Jumps to the given page number
    def jump(self, page) -> None:
        self.page = page
        self.page_image = self.images[page]

    # Renders and caches the pages from the document
    def _cache_pages(self, pages: Queue) -> None:
        renderer = poppler.PageRenderer()

        while not pages.empty():
            page = pages.get_nowait()

            # Nothing left -- finish the thread
            if page is None:
                break

            self.images[page] = self._render_page(page, renderer)

    # Generates a pixel map for the given page 
    def _render_page(self, page_number: int, renderer: poppler.PageRenderer) -> numpy.array:
        # Render the image in Poppler
        page = self.pdf.create_page(page_number)
        page_image = renderer.render_page(page, self.resolution, self.resolution)

        # Convert to a PIL image
        image = Image.frombytes(
            'RGBA',
            (page_image.width, page_image.height),
            page_image.data,
            'raw',
            str(page_image.format),
        )

        # Make sure it matches the expected image size
        if image.size[0] < self.width or image.size[1] < self.height:
            image = image.resize((self.width, self.height), Image.BILINEAR)

        # Make sure it matches the display mode
        if image.mode != 'RGB':
            image = image.convert('RGB')

        return numpy.array(image)
