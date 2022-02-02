#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_dir='/opt/retropie/supplementary/manualkit'

install() {
  "$bin_dir/manualkit/setup.sh" install

  sudo mkdir -p "$install_dir"
  sudo rsync -av "$bin_dir/manualkit/" "$install_dir/" --delete

  cp -v "$config_dir/manuals/manualkit.conf" '/opt/retropie/configs/all/manualkit.conf'

  # Convert txt/html to pdf
  sudo apt install -y chromium

  # Convert images to pdf
  sudo apt install -y img2pdf

  # Convert cbr archives to pdf
  sudo apt install -y unrar

  # Convert doc to pdf
  sudo apt install -y unoconv

  # OCR PDF to make it searchable
  sudo pip3 install ocrmypdf==13.3.0
  sudo apt install -y \
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

  # Install newer version of ghostscript that can handle certain jpx/jbig2 images
  ghostscript_version=9.55.0
  local current_ghostscript_version="$(cat /usr/local/etc/ghostscript.version 2>/dev/null || true)"
  if [ "$(gs --version)" != "$ghostscript_version" ] || [ "$current_ghostscript_version" != "$ghostscript_version" ]; then
    # Download ghostscript source
    rm -rf "$tmp_dir/ghostscript"
    mkdir "$tmp_dir/ghostscript"
    wget "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${ghostscript_version//.}/ghostscript-$ghostscript_version.tar.gz" -O "$tmp_dir/ghostscript/ghostscript.tar.gz"
    tar -zxvf "$tmp_dir/ghostscript/ghostscript.tar.gz" -C "$tmp_dir/ghostscript"

    pushd "$tmp_dir/ghostscript/ghostscript-$ghostscript_version"
    ./configure
    make
    sudo make install

    echo "$ghostscript_version" | sudo tee /usr/local/etc/ghostscript.version

    popd
    rm -rf "$tmp_dir/ghostscript"
  fi
}

uninstall() {
  rm -rfv "$install_dir" '/opt/retropie/configs/all/manualkit.conf'
  sudo pip3 uninstall -y evdev pyudev psutil PyMuPDF
  sudo apt remove -y chromium img2pdf unrar unoconv
}

"${@}"
