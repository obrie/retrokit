import fitz
import math
from pathlib import Path

# Represents a PDF-based manual
class PDF():
    NO_MANUAL_TEXT = 'No manual found'
    NO_MANUAL_FONTSIZE = 28
    NO_MANUAL_HEIGHT = 37
    MAX_ZOOM = 5.0

    def __init__(self,
        path: str,
        width: int,
        height: int,
        buffer_width: int,
        buffer_height: int,
        turbo_skip: int = 2,
    ) -> None:
        self.path = path
        self.width = width
        self.height = height
        self.buffer_width = buffer_width
        self.buffer_height = buffer_height
        self.page = None
        self.zoom = 1.0
        self.clip_rect = fitz.Rect()

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
    def next(self, turbo: bool = False) -> None:
        if turbo:
            skip = self.turbo_skip
        else:
            skip = 1

        next_page = self.page + skip
        if next_page >= self.page_count:
            next_page = 0

        self.jump(next_page)

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self, turbo: bool = False) -> None:
        if turbo:
            skip = self.turbo_skip
        else:
            skip = 1

        prev_page = self.page - skip
        if prev_page < 0:
            prev_page = max(0, self.page_count - skip)

        self.jump(prev_page)

    # Jumps to the given page number
    def jump(self, page_number: int) -> None:
        if self.page != page_number:
            self.page = page_number
            self.page_image = self._render_page(page_number)

    # 
    def zoom_in(self) -> None:
        print('zoom in')
        pass

    def zoom_out(self) -> None:
        print('zoom out')
        pass

    def move_left(self) -> None:
        print('move left')
        pass

    def move_right(self) -> None:
        print('move right')
        pass

    def move_up(self) -> None:
        print('move up')
        pass

    def move_down(self) -> None:
        print('move down')
        pass

    # Renders image data for the given page number.
    # 
    # This will automatically zoom and center the image according to the width /
    # height configured for the PDF.
    def _render_page(self, page_number: int) -> bytes:
        page = self.document[page_number]


    # r = dlist.rect  # the page rectangle
    # clip = r
    # # ensure image fits screen:
    # # exploit, but do not exceed width or height
    # zoom_0 = 1
    # if max_size:
    #     zoom_0 = min(1, max_size[0] / r.width, max_size[1] / r.height)
    #     if zoom_0 == 1:
    #         zoom_0 = min(max_size[0] / r.width, max_size[1] / r.height)

    # mat_0 = fitz.Matrix(zoom_0, zoom_0)

    # if not zoom:  # show the total page
    #     pix = dlist.get_pixmap(matrix=mat_0, alpha=False)
    # else:
    #     w2 = r.width / 2  # we need these ...
    #     h2 = r.height / 2  # a few times
    #     clip = r * 0.5  # clip rect size is a quarter page
    #     tl = zoom[0]  # old top-left
    #     tl.x += zoom[1] * (w2 / 2)  # adjust topl-left ...
    #     tl.x = max(0, tl.x)  # according to ...
    #     tl.x = min(w2, tl.x)  # arrow key ...
    #     tl.y += zoom[2] * (h2 / 2)  # provided, but ...
    #     tl.y = max(0, tl.y)  # stay within ...
    #     tl.y = min(h2, tl.y)  # the page rect
    #     clip = fitz.Rect(tl, tl.x + w2, tl.y + h2)
    #     # clip rect is ready, now fill it
    #     mat = mat_0 * fitz.Matrix(2, 2)  # zoom matrix
    #     pix = dlist.get_pixmap(alpha=False, matrix=mat, clip=clip)
    # img = pix.tobytes("ppm")  # make PPM image from pixmap for tkinter
    # return img, clip.tl  # return image, clip position

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
