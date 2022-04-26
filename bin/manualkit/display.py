from __future__ import annotations

import ctypes
import ctypes.util

from contextlib import contextmanager
from typing import Generator, Optional, Tuple

# DispmanX C API
bcm = ctypes.CDLL(ctypes.util.find_library('bcm_host'))

# Generates a tuple of c_int objects
def _c_ints(values: Tuple[int]) -> None:
    return (ctypes.c_int * len(values))(*values)

# Provides image rendering for DispmanX displays
# 
# TODO: This should get supplemented with EGL / DRM if possible one day.
class Display():
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

    def __init__(self, background_layer: int = -1000, foreground_layer: int = 10011) -> None:
        self.background_layer = int(background_layer)
        self.foreground_layer = int(foreground_layer)
        self.current_layer = self.background_layer

        # Create a connection to the display
        bcm.bcm_host_init()

        # Look up the display dimensions
        width = ctypes.c_int()
        height = ctypes.c_int()
        success = bcm.graphics_get_display_size(0, ctypes.byref(width), ctypes.byref(height)) 
        assert success >= 0
        self.width = width.value
        self.height = height.value

        # Proper and efficient rendering in dispmanx requires that the width / height be
        # aligned to 16 bytes.  Any additional pixels beyond the actual dimensions of the
        # display will be represented as black pixels and simply not be drawn.
        self.buffer_width = self._align_up(self.width, 16)
        self.buffer_height = self._align_up(self.height, 16)

        # Get a handle to the LCD (0) display
        self.handle = bcm.vc_dispmanx_display_open(0)
        assert self.handle != 0

        # Define display coordinates.  Note we are not doing any 16-pixel alignment
        # on the width / height.  This is a not the most efficient implementation,
        # but there's currently no indication that we need to optimize here.
        # 
        # If needed, we can eventually switch to having a separate buffer_width/
        # buffer_height/buffer_rect that the images get written into.
        self.src_rect = _c_ints((0, 0, self.buffer_width << 16, self.buffer_height << 16))
        self.dest_rect = _c_ints((0, 0, self.buffer_width, self.buffer_height))
        self.pitch = self.buffer_width * 3

        # Create image resource
        self._create_window()

    # Whether the display is currently visible
    @property
    def visible(self) -> bool:
        return self.current_layer == self.foreground_layer

    # Show an empty black layer
    def show(self) -> None:
        self.change_layer(self.foreground_layer)

    # Hides the layer
    def hide(self) -> None:
        self.change_layer(self.background_layer)

    # Clears the layer by drawing all black
    def clear(self) -> None:
        self.draw(b'\x00' * self.pitch * self.buffer_height)

    # Changes the image to be displayed at the given dispmanx layer.
    # This allows manualkit to be hidden by putting it behind the
    # framebuffer (< -127) or visible by putting it in front of the
    # framebuffer (> -127).
    def change_layer(self, layer: int) -> None:
        with self._update_display() as dispman_update:
            bcm.vc_dispmanx_element_change_layer(dispman_update, self.image_element, layer)

        self.current_layer = layer

    # Draws the given image data to the screen
    def draw(self, image_data: bytes) -> None:
        result = bcm.vc_dispmanx_resource_write_data(
            self.image_resource,
            self.IMAGE_TYPE,
            self.pitch,
            ctypes.c_char_p(image_data),
            ctypes.byref(self.dest_rect),
        )

        # Mark it as modified in order to refresh the scree
        with self._update_display() as dispman_update:
            bcm.vc_dispmanx_element_modified(
                dispman_update,
                self.image_element,
                ctypes.byref(self.dest_rect),
            )

    # Cleans up the elements / resources on the display
    def close(self) -> None:
        self.hide()

        if self.image_resource:
            bcm.vc_dispmanx_resource_delete(self.image_resource)
            self.image_resource = None

        if self.handle:
            bcm.vc_dispmanx_display_close(self.handle)
            self.handle = None

    # Show an empty black layer
    def _create_window(self) -> None:
        vc_image_handle = ctypes.c_uint()
        self.image_resource = bcm.vc_dispmanx_resource_create(
            self.IMAGE_TYPE,
            self.buffer_width,
            self.buffer_height,
            ctypes.byref(vc_image_handle),
        )
        assert self.image_resource != 0

        # Create the area for us to draw on
        with self._update_display() as dispman_update:
            alpha_config = _c_ints((
                # Pick up source alpha from the image
                self.DISPMANX_FLAGS_ALPHA_FROM_SOURCE,
                # Opacity (0 - 255)
                255,
                # Mask resource handle
                0,
            ))
            self.image_element = bcm.vc_dispmanx_element_add(
                dispman_update,
                self.handle,
                self.background_layer,
                ctypes.byref(self.dest_rect),
                self.image_resource,
                ctypes.byref(self.src_rect),
                self.DISPMANX_PROTECTION_NONE,
                ctypes.byref(alpha_config),
                0, # clamp
                self.DISPMANX_NO_ROTATE, # transform
            )
            assert self.image_element != 0

    def _align_up(self, value, align_to):
        return ((value + align_to - 1) & ~(align_to - 1))

    # Starts the process for modifying the display
    @contextmanager
    def _update_display(self) -> Generator[ctypes.c_int, None, None]:
        priority = 10
        dispman_update = bcm.vc_dispmanx_update_start(priority)
        assert dispman_update != 0

        yield dispman_update

        result = bcm.vc_dispmanx_update_submit_sync(dispman_update)
        assert result == 0
