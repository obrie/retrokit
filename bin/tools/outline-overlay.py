#!/usr/bin/python3

import argparse
from PIL import Image, ImageDraw

# Converts a 1080p image to be compatible with Lightguns like Sinden by
# creating a rectangular white border around the gameplay area
def make(
    source: str,
    target: str,
    top: int = 0,
    right: int = 0,
    bottom: int = 0,
    left: int = 0,
    width: int = 15,
    color: str = '#ffffff',
    output_format: str = 'PNG',
) -> None:
    image = Image.open(source)

    # Convert to RGB so that we can draw our outline
    if image.mode != 'RGBA':
        rgba_image = image.convert('RGBA')
    else:
        rgba_image = image

    drawing = ImageDraw.Draw(rgba_image)

    # Use the pixel in the middle of the image for a reference for how to fill the
    # rectangle.  This should typically just be a transparent pixel.
    reference_fill_pixel = image.getpixel((image.width / 2, image.height / 2))
    drawing.rectangle(
        [(left, top), (image.width + right - 1, image.height + bottom - 1)],
        fill=reference_fill_pixel,
        outline=color,
        width=width,
    )

    # Convert back to the original image's format
    if image.mode != 'RGBA':
        output_image = rgba_image.convert(image.mode)
    else:
        output_image = rgba_image

    # Save the image
    output_image.save(target)

def main() -> None:
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument(dest='source', help='Source path of the image')
    parser.add_argument(dest='target', help='Target path for the image')
    parser.add_argument('--top', type=int, help='Border width in pixels')
    parser.add_argument('--right', type=int, help='Border width in pixels')
    parser.add_argument('--bottom', type=int, help='Border width in pixels')
    parser.add_argument('--left', type=int, help='Border width in pixels')
    parser.add_argument('--width', type=int, help='Border width in pixels')
    parser.add_argument('--color', help='Border color')
    parser.add_argument('--format', dest='output_format', help='Image output format')
    args = parser.parse_args()
    make(**vars(args))

if __name__ == '__main__':
    main()
