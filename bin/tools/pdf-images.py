#!/usr/bin/python3

# Intended to look like poppler's `pdfimages -list` command but with some
# additional data useful for pdf compression.

from typing import Tuple
import argparse
import fitz
import math

# Map colorspace names to their corresponding profile
colorspaces = {
    'DeviceRGB': fitz.Colorspace(fitz.CS_RGB),
    'DeviceGray': fitz.Colorspace(fitz.CS_GRAY),
    'DeviceCMYK': fitz.Colorspace(fitz.CS_CMYK),
    'ICCBased': fitz.Colorspace(fitz.CS_RGB),
}

storage_units = ['B', 'K', 'M', 'G', 'T', 'P', 'E', 'Z']

# Generate a human-readable storage value
def sizeof_fmt(num: float) -> str:
    for unit in storage_units:
        if abs(num) < 1024.0:
            return f'{num:3.1f}{unit}'
        num /= 1024.0
    return f'{num:.1f}Y'

# This is a highly optimized version of Page.get_image_rects.  This uses several
# shortcuts to avoid generating image data digests when possible (since it's
# incredibly slow).
def get_image_rects(doc: fitz.Document, page: fitz.Page, image: Tuple) -> (fitz.Rect, fitz.Matrix):
    image_infos = page.get_image_info()
    image_info = None
    xref, smask, width, height, *rest = image

    if len(image_infos) == 1 or len(page.get_images()) == 1:
        # Only one info object -- use it
        image_info = image_infos[0]
    else:
        # Find distinct matching info objects
        image_infos = list(filter(lambda info: info['width'] == width and info['height'] == height, image_infos))
        for info in image_infos:
            if 'number' in info:
                info.pop('number')
        image_infos = list({frozenset(d.items()): d for d in image_infos}.values())

        if len(image_infos) == 1:
            # Only one distinct match -- use it
            image_info = image_infos[0]
        else:
            # Find based on matching digest (again, optimizing Page.get_image_rects).
            # This is so we don't have to look up the file size separately later.
            pix = fitz.Pixmap(page.parent, xref)
            digest = pix.digest
            del pix
            image_info = next(im for im in page.get_image_info(hashes=True) if im['digest'] == digest)

    rect = fitz.Rect(image_info['bbox'])
    matrix = fitz.Matrix(image_info['transform'])

    return (rect, matrix)

def run(path: str) -> None:
    doc = fitz.open(path)
    image_num = 0

    for page in doc.pages():
        # Page's cropbox (to help identify what part of an image is actually
        # being displayed)
        page_bbox = page.bound() # already rotated
        cropbox_width = page_bbox.width
        cropbox_height = page_bbox.height
        page_rotation = abs(page.rotation) % 180

        image_count = 0

        # Track smasks so we can ignore them
        smasks = set()
        for image in page.get_images():
            image_count += 1
            xref, smask, *rest = image
            if smask and smask != 0:
                smasks.add(smask)

        for image in page.get_images(full=True):
            xref, smask, width, height, bpc, colorspace_name, alt_colorspace_name, name, filter_name, referencer_xref = image

            # Skip masks
            if xref in smasks:
                continue

            # Skip images without colorspaces
            if colorspace_name == '':
                continue

            # Skip "dead" (hidden) images
            image_bbox_results = page.get_image_bbox(image, transform=True)
            if type(image_bbox_results) != tuple or image_bbox_results[1] == fitz.Matrix():
                continue

            # Calculate accurate bound boxes for the image
            image_bbox_results = get_image_rects(doc, page, image)
            bbox, matrix = image_bbox_results

            interpolate = 'yes' if doc.xref_get_key(xref, 'Interpolate') == 'true' else 'no'

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

            full_image_rotation = abs(page.rotation + image_rotation) % 180

            # Image's bounding box (already transformed / rotated)
            bbox_width = bbox.width
            bbox_height = bbox.height

            # Adjust the bbox dimensions based on the page's rotation
            if page_rotation == 90:
                bbox_width, bbox_height = bbox_height, bbox_width

            # Adjust the *original* image dimensions based on its computed rotation
            if full_image_rotation == 90:
                width, height = height, width

            # Calculate the image's resolution
            ppi_x = round(width * 72 / bbox_width)
            ppi_y = round(height * 72 / bbox_height)

            # Colorspace info
            if colorspace_name in colorspaces:
                color_components = colorspaces[colorspace_name].n
            else:
                color_components = 1

            # Calculate the actual dimensions of the image that are visible.
            # These diimensions can then be used to help identify the target
            # downsample resolution for an image.
            if int(bbox_width) > int(cropbox_width):
                # The image is cropped -- adjust how wide it appears
                cropped_width = round(width / (bbox_width / cropbox_width))
            else:
                cropped_width = width

            if int(bbox_height) > int(cropbox_height):
                # The image is cropped -- adjust how tall it appears
                cropped_height = round(height / (bbox_height / cropbox_height))
            else:
                cropped_height = height

            # Compression info
            compressed_size = len(doc.xref_stream_raw(xref))
            uncompressed_size = width * height * color_components * bpc / 8
            compressed_ratio = compressed_size / uncompressed_size

            print('\t'.join([
                str(page.number + 1),
                str(image_num),
                'image', # type
                str(width),
                str(height),
                colorspace_name,
                str(color_components),
                str(bpc),
                filter_name or 'FlateDecode',
                interpolate,
                str(xref),
                '0', # generation
                str(ppi_x),
                str(ppi_y),
                str(sizeof_fmt(compressed_size)),
                str(round(compressed_ratio * 100, 1)) + '%',
                str(full_image_rotation),
                str(cropped_width),
                str(cropped_height),
            ]))

            image_num += 1

def main() -> None:
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument(dest='path', help='Path of the pdf')
    args = parser.parse_args()
    run(**vars(args))

if __name__ == '__main__':
    main()
