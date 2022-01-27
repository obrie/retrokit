#!/usr/bin/python3

# Intended to look like poppler's `pdfimages -list` command but with some
# additional data useful for pdf compression.

from __future__ import annotations

import argparse
import fitz
import math
from typing import Generator, List, Tuple

class Image:
    # Map colorspace names to their corresponding profile
    COLORSPACES = {
        'DeviceRGB': fitz.Colorspace(fitz.CS_RGB),
        'DeviceGray': fitz.Colorspace(fitz.CS_GRAY),
        'DeviceCMYK': fitz.Colorspace(fitz.CS_CMYK),
        'ICCBased': fitz.Colorspace(fitz.CS_RGB),
    }

    def __init__(self, page: Page, rendering: dict) -> None:
        self.page = page
        self.xref = rendering.get('xref')
        self.inline = rendering.get('inline') == True
        self.width = rendering['width']
        self.height = rendering['height']
        self.bpc = rendering['bpc']
        self.colorspace_name = rendering.get('colorspace_name')
        self.filter_name = rendering.get('filter_name') or 'FlateDecode'
        self.bbox = fitz.Rect(rendering['bbox'])
        self.matrix = fitz.Matrix(rendering['transform'])

        # Memoized properties
        self._compressed_size = None
        self._rotation = None

        # Perform necessary rotations
        if self.can_downsample():
            # Adjust the *original* image dimensions based on its computed rotation
            if self.rotation == 90:
                self.width, self.height = self.height, self.width

            # Adjust the bbox dimensions based on the page's rotation
            if self.page.rotation == 90:
                bbox = self.bbox
                self.bbox = fitz.Rect(bbox.x1, bbox.x0, bbox.y1, bbox.y0)

    # Can this image be downsampled?
    # 
    # * Not inline
    # * Has a colorspace (i.e. is not a stencil)
    def can_downsample(self) -> bool:
        return not self.inline and self.xref and self.colorspace_name

    # The document this image belongs to
    @property
    def doc(self) -> Document:
        return self.page.doc

    # Whether pixels are interpolated when scaling up
    @property
    def interpolate(self) -> bool:
        return self.doc._doc.xref_get_key(self.xref, 'Interpolate') == 'true'

    # Rotation degree of dimensions (0 or 90).  This accounts for the page's rotation.
    @property
    def rotation(self) -> int:
        if self._rotation is None:
            matrix = self.matrix

            # Identify the rotation of the image
            image_rotation = None
            if min(matrix.a, matrix.d) > 0 and matrix.b == matrix.c == 0:
                image_rotation = 0
            elif matrix.a == matrix.d == 0:
                if matrix.b > 0 and matrix.c < 0:
                    image_rotation = 90
                elif matrix.b < 0 and matrix.c > 0:
                    image_rotation = -90
                else:
                    image_rotation = 0 # unknown, default to no rotation
            elif min(matrix.a, matrix.d) < 0 and matrix.b == matrix.c == 0:
                image_rotation = 180
            else:
                image_rotation = 0 # unknown, default to no rotation

            self._rotation = abs(self.page.rotation + image_rotation) % 180

        return self._rotation

    # Image's x-resolution
    @property
    def ppi_x(self) -> int:
        return round(self.width * 72 / self.bbox.width)

    # Image's y-resolution
    @property
    def ppi_y(self) -> int:
        return round(self.height * 72 / self.bbox.height)

    # Number of components in the colorspace
    @property
    def color_components(self) -> int:
        # Colorspace info
        if self.colorspace_name in self.COLORSPACES:
            return self.COLORSPACES[self.colorspace_name].n
        else:
            return 1

    # The actual horizontal dimensions of the image that are visible.
    @property
    def cropped_width(self) -> float:
        if int(self.bbox.width) > int(self.page.bbox.width):
            # The image is cropped -- adjust how wide it appears
            return round(self.width / (self.bbox.width / self.page.bbox.width))
        else:
            return self.width

    # The actual vertical dimensions of the image that are visible.
    @property
    def cropped_height(self) -> float:
        if int(self.bbox.height) > int(self.page.bbox.height):
            # The image is cropped -- adjust how tall it appears
            return round(self.height / (self.bbox.height / self.page.bbox.height))
        else:
            return self.height

    # The disk usage when compressed
    @property
    def compressed_size(self) -> int:
        if self._compressed_size is None:
            self._compressed_size = len(self.doc._doc.xref_stream_raw(self.xref))

        return self._compressed_size

    # The disk usage when uncompressed
    @property
    def uncompressed_size(self) -> int:
        return self.width * self.height * self.color_components * self.bpc / 8

    # The compression ratio for the image
    @property
    def compressed_ratio(self) -> float:
        return self.compressed_size / self.uncompressed_size

class Page:
    def __init__(self, doc: fitz.Document, page: fitz.Page) -> None:
        self.doc = doc
        self._page = page

        # Page's cropbox (to help identify what part of an image is actually
        # being displayed), already rotated
        self.bbox = page.bound()

        # Cross-referenced images (ignore masks since they can't be easily downsampled)
        self.xref_images = list(filter(lambda xref_image: not xref_image['is_mask'], map(self._build_xref_image, page.get_images(full=True))))

        # Lazy, memoized attributes

        # Match block numbers to image hashes
        self._block_hashes = None

    # Page number
    @property
    def number(self) -> int:
        return self._page.number

    # Visible images in the page that can be downsampled
    @property
    def images(self) -> Generator[int, None, None]:
        # No images for us to actually yield
        if len(self.xref_images) == 0:
            return

        for image_info in self._page.get_image_info():
            image = self._build_image(image_info)

            # Only return the image if we decide it's a candidate to be downsampled
            if image.can_downsample():
                yield image

    # The page's rotation (0 or 90)
    @property
    def rotation(self) -> int:
        return abs(self._page.rotation) % 180

    # Looks up the image info by xref (this is slower and should be avoided if possible)
    def _build_image(self, info: dict) -> List[Tuple]:
        matching_xref_images = []
        xref_image = {}

        # 1. Attempt to find images with the same imgae digest
        if 'digest' in info:
            matching_xref_images = list(filter(lambda xref_image: info['digest'] == xref_image.get('digest'), self.xref_images))[0:1]

        # 2. Attempt to find images with the same width and height
        if not matching_xref_images:
            matching_xref_images = list(filter(lambda xref_image: info['width'] == xref_image['width'] and info['height'] == xref_image['height'], self.xref_images))

        if len(matching_xref_images) == 0:
            # Inline image: ignore
            xref_image = {'inline': True}
        elif len(matching_xref_images) == 1:
            # Exact match
            xref_image = matching_xref_images[0]
            self.xref_images.remove(xref_image)
        else:
            # 3. Look up md5 hashes for rendered images
            if not self._block_hashes:
                self._block_hashes = {info['number']: info['digest'] for info in self._page.get_image_info(hashes=True)}

            info['digest'] = self._block_hashes[info['number']]

            for xref_image_match in matching_xref_images:
                # 4. Calculate md5 hash for xref image to match the rendered image
                if 'digest' not in xref_image_match:
                    pix = fitz.Pixmap(self._page.parent, xref_image_match['xref'])
                    xref_image_match['digest'] = pix.digest
                    del pix

                # 5. Find an xref image that matches our image digest
                if xref_image_match['digest'] == info['digest']:
                    xref_image = xref_image_match
                    self.xref_images.remove(xref_image)
                    break

        return Image(self, {**info, **(xref_image or {})})

    # Translate xref image tuples to dictionaries specific to our use case
    def _build_xref_image(self, xref_image: Tuple) -> dict:
        xref, smask, width, height, bpc, colorspace_name, alt_colorspace_name, name, filter_name, referencer_xref = xref_image

        return {
            'xref': xref,
            'is_mask': smask != 0,
            'width': width,
            'height': height,
            'bpc': bpc,
            'colorspace_name': colorspace_name,
            'filter_name': filter_name,
        }

class Formatter:
    STORAGE_UNITS = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']

    # Generate a human-readable storage value
    @classmethod
    def sizeof_fmt(cls, num: float) -> str:
        for unit in cls.STORAGE_UNITS:
            if abs(num) < 1024.0:
                return f'{num:3.1f}{unit}'
            num /= 1024.0
        return f'{num:.1f}Y'

    # Generates a human-readable percentage value
    @classmethod
    def percent_fmt(cls, num: float) -> str:
        return str(round(num * 100, 1)) + '%'

class Document:
    def __init__(self, path: str) -> None:
        self._doc = fitz.open(path)
    
    # Prints information about the xref images in the document
    def print(self) -> None:
        image_number = 0

        for page in self._doc.pages():
            page = Page(self, page)

            for image in page.images:
                print('\t'.join(map(str, [
                    page.number + 1,
                    image_number,
                    'image', # type
                    image.width,
                    image.height,
                    image.colorspace_name,
                    image.color_components,
                    image.bpc,
                    image.filter_name,
                    'yes' if image.interpolate else 'no',
                    image.xref,
                    '0', # generation
                    image.ppi_x,
                    image.ppi_y,
                    Formatter.sizeof_fmt(image.compressed_size),
                    Formatter.percent_fmt(image.compressed_ratio),
                    image.rotation,
                    image.cropped_width,
                    image.cropped_height,
                ])))

                image_number += 1

def main() -> None:
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument(dest='path', help='Path of the pdf')
    args = parser.parse_args()
    Document(**vars(args)).print()

if __name__ == '__main__':
    main()
