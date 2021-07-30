import fitz

# Represents a PDF-based manual
class PDF():
    def __init__(self,
        path: str,
        width: int,
        height: int,
        resolution: int = 150,
    ) -> None:
        self.path = path
        self.width = width
        self.height = height
        self.resolution = int(resolution)
        self.document = fitz.open(self.path)
        self.page = 0

    # Gets the image data for the current page
    @property
    def page_image(self) -> bytes:
        return self._render_page(self.page)

    # TODO
    @property
    def page_count(self) -> int:
        return self.document.pageCount

    # Moves to the next page or goes back to the beginning if already on the last page
    def next(self) -> None:
        next_page = self.page + 1
        if next_page >= self.page_count:
            next_page = 0

        self.jump(next_page)

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self) -> None:
        prev_page = self.page - 1
        if prev_page < 0:
            prev_page = self.page_count - 1

        self.jump(prev_page)

    # Jumps to the given page number
    def jump(self, page) -> None:
        self.page = page

    def _render_page(self, page_number: int) -> bytes:
        page = self.document[page_number]
        zoom = min(self.width / page.rect.width, self.height / page.rect.height)
        image = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)

        offset_x = int((self.width - image.width) / 2)
        offset_y = int((self.height - image.height) / 2)

        image.set_origin(offset_x, offset_y)

        padded_image = fitz.Pixmap(fitz.Colorspace(fitz.CS_RGB), (0, 0, self.width, self.height), False)
        padded_image.copy(image, (-offset_x, -offset_y, image.width + offset_x, image.height + offset_y))

        return padded_image.samples
