import ctypes
import numpy
import os
import time

from PIL import Image
from contextlib import contextmanager

bcm = ctypes.CDLL('/opt/vc/lib/libbcm_host.so')

DISPMANX_FLAGS_ALPHA_FROM_SOURCE = 0
DISPMANX_PROTECTION_NONE = 0
DISPMANX_NO_ROTATE = 0
VC_IMAGE_RGB888 = 5

def c_ints(x):
  """Return a tuple of c_int, converted from a list of Python variables."""
  return (ctypes.c_int * len(x))(*x)

class ManualKit():
    def __init__(self, imgw, imgh, layer):
        self.layer = layer
        bcm.bcm_host_init()

        self.width, self.height = ctypes.c_int(), ctypes.c_int()

        # choose the next smalles multiple of 16 for width and height (might some of the bg)
        self.imgw, self.imgh = self._align_down(imgw, 16), self._align_down(imgh, 16)

        success = bcm.graphics_get_display_size(0, ctypes.byref(self.width), ctypes.byref(self.height)) 
        assert success >= 0

        # LCD setting (0)
        self.dispman_display = bcm.vc_dispmanx_display_open(0)
        assert self.dispman_display != 0

        self.img_element = None
        self.img_resource = None

        self.create_buffer()

    # Cleans up the elements / resources on the display
    def close(self):
        with self.bcm_update() as dispman_update:
            bcm.vc_dispmanx_element_remove(dispman_update, self.img_element)

        bcm.vc_dispmanx_resource_delete(self.img_resource)
        bcm.vc_dispmanx_display_close(self.dispman_display)

    @contextmanager
    def bcm_update(self):
        dispman_update = bcm.vc_dispmanx_update_start(10)
        assert dispman_update != 0

        yield dispman_update

        result = bcm.vc_dispmanx_update_submit_sync(dispman_update)
        assert result == 0

    def _align_up(self, n, alignTo):
        return ((n + alignTo - 1) & ~(alignTo - 1))

    def _align_down(self, n, alignTo):
        return n & ~(alignTo - 1)

    def create_buffer(self):
        self.vc_image_ptr = ctypes.c_uint()
        self.pitch = self.imgw * 3
        assert(self.pitch % 32 == 0)

        self.imgtype = VC_IMAGE_RGB888
        with self.bcm_update() as dispman_update:
            self.img_resource = bcm.vc_dispmanx_resource_create(
                self.imgtype,
                self.imgw,
                self.imgh,
                ctypes.byref(self.vc_image_ptr),
            )
            assert self.img_resource != 0

            self.src_rect = c_ints((0, 0, self.imgw << 16, self.imgh << 16))

            # scale width so that aspect ratio is retained with display height - might crop right part of the bg
            dstw = int(self.h.value * self.imgw / self.imgh)
            self.dst_rect = c_ints((0, 0, dstw, self.h))
            self.alpha = c_ints((DISPMANX_FLAGS_ALPHA_FROM_SOURCE, 255, 0))
            self.img_element = bcm.vc_dispmanx_element_add(
                dispman_update,
                self.dispman_display,
                self.layer,
                ctypes.byref(self.dst_rect),
                self.img_resource,
                ctypes.byref(self.src_rect),
                DISPMANX_PROTECTION_NONE,
                ctypes.byref(self.alpha),
                0,
                DISPMANX_NO_ROTATE,
            )

            assert(self.img_element != 0)

    def loadImg(self, path):
        from poppler import load_from_file, PageRenderer

        pdf_document = load_from_file(path)
        page_1 = pdf_document.create_page(0)

        renderer = PageRenderer()
        pdf_image = renderer.render_page(page_1, 150, 150)

        image = Image.frombytes(
            "RGBA",
            (pdf_image.width, pdf_image.height),
            pdf_image.data,
            "raw",
            str(pdf_image.format),
        )

        # image = Image.open(path)
        if image.size[0] < self.imgw or image.size[1] < self.imgh:
            image = image.resize((self.imgw, self.imgh), Image.BILINEAR)

        if image.mode != "RGB":
            image = image.convert("RGB")

        return image

    def set_img(self, path):
        img = self.loadImg(path)
        bmpRect = c_ints((0, 0, self.imgw, self.imgh))
        imgbuffer = numpy.array(img)
        result = bcm.vc_dispmanx_resource_write_data(self.img_resource,
                                                     self.imgtype,
                                                     self.pitch,
                                                     imgbuffer.ctypes.data,
                                                     ctypes.byref(bmpRect))
        with self.bcm_update() as dispman_update:
            bcm.vc_dispmanx_element_modified(dispman_update, self.img_element, ctypes.byref(self.dst_rect));

dsp = DispmanxBG(1920, 1080, -1)
dsp.set_img('/home/pi/.emulationstation/downloaded_media/c64/manuals/180 (Europe) (Budget).good.pdf')
# dsp.set_img('/home/pi/.emulationstation/downloaded_media/c64/manuals/test3/page-001.jpg')
time.sleep(5)
dsp.close()
