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
    fill: bool = True,
    canvas_top: int = 0,
    canvas_right: int = 0,
    canvas_bottom: int = 0,
    canvas_left: int = 0,
    canvas_color: str = None,
    canvas_opacity: int = 255,
    output_format: str = 'PNG',
) -> None:
    image = Image.open(source)

    # Convert to RGBA so that we can draw our outline
    if image.mode != 'RGBA':
        rgba_image = image.convert('RGBA')
    else:
        rgba_image = image

    # Cover parts beyond the outline if requested
    if canvas_color:
        canvas_color = canvas_color.lstrip('#')
        color_len = len(canvas_color)
        canvas_color_rgba = tuple(int(canvas_color[i:i + color_len // 3], 16) for i in range(0, color_len, color_len // 3))

        canvas = Image.new('RGBA', rgba_image.size, canvas_color_rgba + (0,))
        canvas_drawing = ImageDraw.Draw(canvas)

        if canvas_opacity != None and canvas_opacity != '':
            canvas_color_rgba += (int(canvas_opacity),)

        if canvas_left != 0:
            # Left gutter
            canvas_drawing.rectangle(
                [(0, 0), (canvas_left - 1, image.height - 1)],
                fill=canvas_color_rgba,
            )

        if canvas_right != 0:
            # Right gutter
            canvas_drawing.rectangle(
                [(image.width + canvas_right, 0), (image.width - 1, image.height - 1)],
                fill=canvas_color_rgba,
            )

        if canvas_top != 0:
            # Top gutter
            canvas_drawing.rectangle(
                [(0, 0), (image.width - 1, canvas_top - 1)],
                fill=canvas_color_rgba,
            )

        if canvas_bottom != 0:
            # Bottom gutter
            canvas_drawing.rectangle(
                [(0, image.height + canvas_bottom), (image.width - 1, image.height - 1)],
                fill=canvas_color_rgba,
            )

        rgba_image = Image.alpha_composite(rgba_image, canvas)

    drawing = ImageDraw.Draw(rgba_image)

    if fill == True or fill == 'true':
        fill_color = (0, 0, 0, 0)
    else:
        fill_color = None

    # Use the pixel in the middle of the image for a reference for how to fill the
    # rectangle.  This should typically just be a transparent pixel.
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
    parser.add_argument('--canvas_top', type=int, help='Canvas top coordinate, in pixels')
    parser.add_argument('--canvas_right', type=int, help='Canvas right coordinate, in pixels')
    parser.add_argument('--canvas_bottom', type=int, help='Canvas bottom coordinate, in pixels')
    parser.add_argument('--canvas_left', type=int, help='Canvas left coordinate, in pixels')
    parser.add_argument('--canvas_color', help='Canvas color')
    parser.add_argument('--canvas_opacity', help='Canvas opacity (0-255)')
    parser.add_argument('--format', dest='output_format', help='Image output format')
    args = parser.parse_args()
    make(**vars(args))

if __name__ == '__main__':
    main()
