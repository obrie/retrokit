import fitz
import math
from pathlib import Path

# Represents a PDF-based manual
class PDF():
    NO_MANUAL_TEXT = 'No manual found'
    NO_MANUAL_FONTSIZE = 28
    NO_MANUAL_HEIGHT = 37
    MAX_ZOOM_LEVEL = 3
    PERCENT_SHIFT_PER_MOVE = 0.33

    def __init__(self,
        path: str,
        width: int,
        height: int,
        buffer_width: int,
        buffer_height: int,
        supplementary_path: str = None,
        turbo_skip: int = 2,
        zoom_multiplier: float = 1.5,
    ) -> None:
        self.path = path
        self.width = width
        self.height = height
        self.buffer_width = buffer_width
        self.buffer_height = buffer_height
        self.supplementary_path = supplementary_path
        self.zoom_multiplier = zoom_multiplier
        self.zoom_level = 0
        self.page_number = None
        self.clip_rect = fitz.Rect()

        if self.path and Path(self.path).exists():
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

        # Add supplementary material (usually reference info)
        if self.supplementary_path and Path(self.supplementary_path).exists():
            pdf = fitz.open(self.supplementary_path)
            self.document.insert_pdf(pdf)
            pdf.close()

        self.jump(0)

    # Closes the PDF so it can no longer be used
    def close(self) -> None:
        self.document.close()

    # Total number of pages in the PDF
    @property
    def page_count(self) -> int:
        return self.document.pageCount

    # The currently activate PDF page
    @property
    def page(self) -> int:
        return self.document[self.page_number]

    # Moves to the next page or goes back to the beginning if already on the last page
    def next(self, turbo: bool = False) -> None:
        if turbo:
            skip = self.turbo_skip
        else:
            skip = 1

        next_page = self.page_number + skip
        if next_page >= self.page_count:
            next_page = 0

        self.jump(next_page)

    # Moves to the previous page or goes to the end if already on the first page
    def prev(self, turbo: bool = False) -> None:
        if turbo:
            skip = self.turbo_skip
        else:
            skip = 1

        prev_page = self.page_number - skip
        if prev_page < 0:
            prev_page = max(0, self.page_count - skip)

        self.jump(prev_page)

    # Jumps to the given page number
    def jump(self, page_number: int) -> None:
        if self.page_number != page_number:
            self.page_number = page_number
            self.render()

    # Increases the zoom level of the PDF
    def zoom_in(self) -> None:
        if self.zoom_level < self.MAX_ZOOM_LEVEL:
            self.zoom(self.zoom_level + 1)

    # Decreases the zoom level of the PDF
    def zoom_out(self) -> None:
        if self.zoom_level > 0:
            self.zoom(self.zoom_level - 1)

    # Zooms the pdf into the given level
    def zoom(self, level: int) -> None:
        self.zoom_level = level

        # Render a new image with the given x / y center points
        self.render(
            (self.clip_rect.x0 + self.clip_rect.x1) / (2 * self.pixmap.width),
            (self.clip_rect.y0 + self.clip_rect.y1) / (2 * self.pixmap.height),
        )

    # Moves left, when zoomed in, or to the previous page when not zoomed
    def move_left(self) -> None:
        if self.zoom_level == 0:
            self.prev()
        else:
            self.move(x_direction=-1)

    # Moves right, when zoomed in, or to the next page when not zoomed
    def move_right(self) -> None:
        if self.zoom_level == 0:
            self.next()
        else:
            self.move(x_direction=1)

    # Moves up, when zoomed in, or to the previous page when not zoomed
    def move_up(self) -> None:
        if self.zoom_level == 0:
            self.prev()
        else:
            self.move(y_direction=-1)

    # Moves down, when zoomed in, or to the next page when not zoomed
    def move_down(self) -> None:
        if self.zoom_level == 0:
            self.next()
        else:
            self.move(y_direction=1)

    # Moves the current clip rect in the given x / y direction
    # 
    # For example, if x is 1 then we move right.  If x is -1, we move left.
    def move(self, x_direction: int = 0, y_direction: int = 0, percentage: bool = True):
        clip_width = self.clip_rect.width
        clip_height = self.clip_rect.height

        self.pixmap.set_origin(0, 0)
        page_rect = self.pixmap.irect

        # Translate percentage movements to pixel movements
        if percentage:
            x_direction = int(clip_width * self.PERCENT_SHIFT_PER_MOVE) * x_direction
            y_direction = int(clip_height * self.PERCENT_SHIFT_PER_MOVE) * y_direction

        # Calculate new right-most pixel and ensure it's within the min / max values
        if x_direction:
            new_x1 = self.clip_rect.x1 + x_direction
            new_x1 = max(min(new_x1, page_rect.x1), clip_width)

            self.clip_rect.x1 = new_x1
            self.clip_rect.x0 = self.clip_rect.x1 - clip_width

        # Calculate new bottom-most pixel and ensure it's within the min / max values
        if y_direction:
            new_y1 = self.clip_rect.y1 + y_direction
            new_y1 = max(min(new_y1, page_rect.y1), clip_height)

            self.clip_rect.y1 = new_y1
            self.clip_rect.y0 = self.clip_rect.y1 - clip_height

        self.refresh()

    # Renders image data for the given page number.
    def render(self, center_x_percent: float = 0.0, center_y_percent: float = 0.0) -> bytes:
        # Determine the maximum zoom we can ask for before we'd be exceeding the
        # configured width / height
        zoom = min(self.width / self.page.rect.width, self.height / self.page.rect.height)

        # Zoom further based on the user-configured zoom level
        zoom *= (self.zoom_multiplier ** self.zoom_level)

        # Generate the full image based on the zoom level.  We do this instead of
        # just the clipped area in order to improve navigation performance.
        self.pixmap = self.page.get_pixmap(matrix=fitz.Matrix(zoom, zoom), alpha=False)

        # Build the clip rectangle for navigation within the image
        self.clip_rect = fitz.Rect(0, 0, min(self.width, self.pixmap.width), min(self.height, self.pixmap.height))

        # Move to a center point determined by how far we were into the prior
        # zoom level
        self.move(
            x_direction=max(center_x_percent * self.pixmap.width - self.clip_rect.width / 2, 0),
            y_direction=max(center_y_percent * self.pixmap.height - self.clip_rect.height / 2, 0),
            percentage=False,
        )

    # Re-renders and caches the current view of the page
    def refresh(self) -> None:
        # Determine the offset so that the image is centered (for the scenario in which
        # the aspect ratio doesn't match the configured device width / height)
        offset_x = max(int((self.width - self.clip_rect.width) / 2), 0)
        offset_y = max(int((self.height - self.clip_rect.height) / 2), 0)

        # Create a new pixmap based on the PDF width / height that will contain the
        # zoomed page, centered
        padded_image = fitz.Pixmap(fitz.csRGB, (0, 0, self.buffer_width, self.buffer_height), False)

        # Adjust the source to the location we want to copy
        self.pixmap.set_origin(offset_x - int(self.clip_rect.x0), offset_y - int(self.clip_rect.y0))
        padded_image.copy(self.pixmap, (0, 0, self.clip_rect.width + offset_x, self.clip_rect.height + offset_y))

        # Reset the source origin so it's set up appropriately the next time we refresh
        self.pixmap.set_origin(0, 0)

        self.page_image = padded_image.samples
