#!/usr/bin/python3

import argparse
from PIL import Image, ImageDraw, ImageEnhance

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
    fill: bool = True,
    brightness: float = 1.0,
    output_format: str = 'PNG',
) -> None:
    image = Image.open(source)

    # Convert to RGBA so that we can draw our outline
    if image.mode != 'RGBA':
        rgba_image = image.convert('RGBA')
    else:
        rgba_image = image

    # Decrease brightness of image
    enhancer = ImageEnhance.Brightness(rgba_image)
    rgba_image = enhancer.enhance(float(brightness))

    if fill == True or fill == 'true':
        fill_color = (0, 0, 0, 0)
    else:
        fill_color = None

    # Draw the outline
    drawing = ImageDraw.Draw(rgba_image)
    drawing.rectangle(
        [(left, top), (image.width + right - 1, image.height + bottom - 1)],
        fill=fill_color,
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
    parser.add_argument('--top', type=int, help='Outline top coordinate, in pixels')
    parser.add_argument('--right', type=int, help='Outline right coordinate, in pixels')
    parser.add_argument('--bottom', type=int, help='Outline bottom coordinate, in pixels')
    parser.add_argument('--left', type=int, help='Outline left coordinate, in pixels')
    parser.add_argument('--width', type=int, help='Outline width, in pixels')
    parser.add_argument('--color', help='Outline color')
    parser.add_argument('--fill', help='Whether to fill within the outline')
    parser.add_argument('--brightness', help='Brightness enhance (0.0 to 1.0)')
    parser.add_argument('--format', dest='output_format', help='Image output format')
    args = parser.parse_args()
    make(**vars(args))

if __name__ == '__main__':
    main()
