import fitz
import math
from pathlib import Path

# Represents a PDF-based manual
class PDF():
    NO_MANUAL_TEXT = 'No manual found'
    NO_MANUAL_FONTSIZE = 28
    NO_MANUAL_HEIGHT = 37

    def __init__(self,
        path: str,
        width: int,
        height: int,
        buffer_width: int,
        buffer_height: int,
    ) -> None:
        self.path = path
        self.width = width
        self.height = height
        self.buffer_width = buffer_width
        self.buffer_height = buffer_height
        self.page = None

        if Path(self.path).exists():
            self.document = fitz.open(self.path)
        else:
            # Create an empty pdf
            self.document = fitz.open()

            # Calculate width of text
            width = math.ceil(fitz.get_text_length(self.NO_MANUAL_TEXT, fontsize=self.NO_MANUAL_FONTSIZE))

            # Create page that's wider than the text so that it scales well
            page = self.document.new_page(width=width * 3, height=self.NO_MANUAL_HEIGHT)

            # Draw a black background
            page.draw_rect(page.rect, color=(0, 0, 0), fill=(0, 0, 0), overlay=False)

            # Draw the text, positioned in the center
            text_writer = fitz.TextWriter(page.rect)
            text_writer.fill_textbox(
                page.rect,
                self.NO_MANUAL_TEXT,
                pos=(int((page.rect.width - width) / 2), self.NO_MANUAL_FONTSIZE),
                fontsize=self.NO_MANUAL_FONTSIZE,
            )
            text_writer.write_text(page, color=(1, 1, 1))

        self.jump(0)

    # Total number of pages in the PDF
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
    def jump(self, page_number: int) -> None:
        if self.page != page_number:
            self.page = page_number
            self.page_image = self._render_page(page_number)

    # Renders image data for the given page number.
    # 
    # This will automatically zoom and center the image according to the width /
    # height configured for the PDF.
    def _render_page(self, page_number: int) -> bytes:
        page = self.document[page_number]

        # Determine the maximum zoom we can ask for before we'd be exceeding the
        # configured width / height
        zoom = min(self.width / page.rect.width, self.height / page.rect.height)
        image = page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)

        # Determine the offset so that the image is centered
        offset_x = int((self.width - image.width) / 2)
        offset_y = int((self.height - image.height) / 2)
        image.set_origin(offset_x, offset_y)

        # Create a new pixmap based on the PDF width / height that will contain the
        # zoomed page, centered
        padded_image = fitz.Pixmap(fitz.csRGB, (0, 0, self.buffer_width, self.buffer_height), False)
        padded_image.copy(image, (-offset_x, -offset_y, image.width + offset_x, image.height + offset_y))

        return padded_image.samples
