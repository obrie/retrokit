#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='manualkit'
setup_module_desc='manualkit install and configuration for viewing game manuals'

install_dir='/opt/retropie/supplementary/manualkit'
ghostscript_version=9.55.0

depends() {
  "$bin_dir/manualkit/setup.sh" depends

  # Convert txt/html to pdf
  sudo apt install -y chromium

  # Convert images to pdf
  sudo apt install -y img2pdf

  # Convert cbr archives to pdf
  sudo apt install -y unrar-free

  # Convert doc to pdf
  sudo apt install -y unoconv

  # Fix exif data
  sudo apt install -y libimage-exiftool-perl

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
  if [ "$(gs --version)" != "$ghostscript_version" ]; then
    # Download
    mkdir "$tmp_ephemeral_dir/ghostscript"
    wget "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${ghostscript_version//.}/ghostscript-$ghostscript_version.tar.gz" -O "$tmp_ephemeral_dir/ghostscript/ghostscript.tar.gz"
    tar -zxvf "$tmp_ephemeral_dir/ghostscript/ghostscript.tar.gz" -C "$tmp_ephemeral_dir/ghostscript"

    # Compile
    pushd "$tmp_ephemeral_dir/ghostscript/ghostscript-$ghostscript_version"
    ./configure
    make
    sudo make install

    # Clean up
    popd
  fi
}

build() {
  # Copy manualkit to the retropie install path so that nothing depends
  # on retrokit being on the system
  sudo mkdir -p "$install_dir"
  sudo rsync -av "$bin_dir/manualkit/" "$install_dir/" --delete
}

configure() {
  cp -v "$config_dir/manuals/manualkit.conf" '/opt/retropie/configs/all/manualkit.conf'
}

remove() {
  rm -rfv "$install_dir" '/opt/retropie/configs/all/manualkit.conf'

  # Only remove python modules uniquely used by manualkit
  sudo pip3 uninstall -y \
    psutil \
    PyMuPDF \
    ocrmypdf

  sudo apt remove -y \
    chromium \
    img2pdf \
    unrar-free \
    unoconv \
    libimage-exiftool-perl \
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

  sudo rm -rfv /usr/local/share/ghostscript
}

setup "${@}"
