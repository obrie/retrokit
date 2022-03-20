#!/usr/bin/python3

# Provides simple pdf merging functionality.  ghostscript could be used as
# an alternative to this script, but it's much slower and does unnecessary
# processing when all we care about is merging pdfs without changing the
# content.
# 
# In order to avoid installing another system dependency like pdftk, we
# use PyMuPDF instead since we're already using it for other things.

from __future__ import annotations

import argparse
import fitz
import sys

def main() -> None:
    parser = argparse.ArgumentParser(argument_default=argparse.SUPPRESS)
    parser.add_argument(dest='output_path', help='Merged output path of the pdf')
    parser.add_argument(dest='input_paths', help='Input pdf paths', nargs='*')
    args = parser.parse_args()

    output_pdf = fitz.open()

    for input_path in args.input_paths:
        input_pdf = fitz.open(input_path)
        output_pdf.insert_pdf(input_pdf)
        input_pdf.close()

    output_pdf.save(args.output_path)

if __name__ == '__main__':
    main()
