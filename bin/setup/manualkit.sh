#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_dir='/opt/retropie/supplementary/manualkit'

install() {
  "$bin_dir/manualkit/setup.sh" install

  sudo mkdir -p "$install_dir"
  sudo rsync -av "$bin_dir/manualkit/" "$install_dir/" --delete

  cp -v "$config_dir/manuals/manualkit.conf" '/opt/retropie/configs/all/manualkit.conf'

  # Identify per-page PPI easily
  sudo apt install -y poppler-utils
  # Install poppler from source to fix pdfimages not working properly for some pdfs
  # 
  # sudo apt install cmake libboost1.71-dev
  # git clone https://gitlab.freedesktop.org/poppler/poppler.git "$tmp_ephemeral_dir/poppler"
  # pushd "$tmp_ephemeral_dir/poppler"
  # mkdir build
  # pushd build
  # cmake ..
  # make
  # sudo make install
  # sudo ldconfig

  # Convert txt/html to pdf
  sudo apt install -y chromium

  # Convert images to pdf
  sudo apt install -y img2pdf

  # Convert cbr archives to pdf
  sudo apt install -y unrar

  # Convert doc to pdf
  sudo apt install -y unoconv

  # OCR PDF to make it searchable
  sudo apt install -y ocrmypdf \
    tesseract-ocr-ara \
    tesseract-ocr-ces \
    tesseract-ocr-chi-sim \
    tesseract-ocr-dan \
    tesseract-ocr-deu \
    tesseract-ocr-fin \
    tesseract-ocr-fra \
    tesseract-ocr-ita \
    tesseract-ocr-jpn \
    tesseract-ocr-kor \
    tesseract-ocr-nld \
    tesseract-ocr-nor \
    tesseract-ocr-pol \
    tesseract-ocr-por \
    tesseract-ocr-rus \
    tesseract-ocr-spa \
    tesseract-ocr-swe
}

uninstall() {
  rm -rfv "$install_dir" '/opt/retropie/configs/all/manualkit.conf'
  sudo pip3 uninstall -y evdev pyudev psutil PyMuPDF
  sudo apt remove -y chromium img2pdf unrar unoconv
}

"${@}"
