#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='manualkit-tools'
setup_module_desc='manualkit supplementary tools for processing new manuals'

ghostscript_min_version=9.55.0
qpdf_min_version=10.6.3

depends() {
  __depends_conversion_tools
  __depends_exif
  __depends_ocr
  __depends_ghostscript
}

# Tools for converting from different formats to PDF
__depends_conversion_tools() {
  sudo apt install -y
    # Convert txt/html to pdf
    chromium \

    # Convert images to pdf
    img2pdf \

    # Convert cbr archives to pdf
    unrar-free \

    # Convert doc to pdf
    unoconv \

    # Resolution calculations
    bc
}

# Tools for fixing exif data
__depends_exif() {
  sudo apt install -y libimage-exiftool-perl
}

# Tools to make PDFs searchable
__depends_ocr() {
  # Ensure the necessary version of qpdf is installed
  if [ ! `command -v qpdf` ] || version_lt "$(qpdf --version | grep -oE 'version [0-9\.]+')" "version $qpdf_min_version"; then
    sudo apt remove -y qpdf libqpdf-dev

    # Depends to compile
    sudo apt install -y libjpeg-dev

    # Download
    mkdir "$tmp_ephemeral_dir/qpdf"
    wget "https://github.com/qpdf/qpdf/releases/download/release-qpdf-$qpdf_min_version/qpdf-$qpdf_min_version.tar.gz" -O "$tmp_ephemeral_dir/qpdf/qpdf.tar.gz"
    tar -zxvf "$tmp_ephemeral_dir/qpdf/qpdf.tar.gz" -C "$tmp_ephemeral_dir/qpdf"

    # Compile
    pushd "$tmp_ephemeral_dir/qpdf/qpdf-$qpdf_min_version"
    ./configure
    make
    sudo make install
    sudo ldconfig

    # Clean up
    popd
  else
    echo "qpdf is already the minimum required version ($qpdf_min_version)"
  fi

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
}

# Install newer version of ghostscript that can handle certain jpx/jbig2 images
__depends_ghostscript() {
  if version_lt "$(gs --version)" "$ghostscript_min_version"; then
    # Download
    mkdir "$tmp_ephemeral_dir/ghostscript"
    wget "https://github.com/ArtifexSoftware/ghostpdl-downloads/releases/download/gs${ghostscript_min_version//.}/ghostscript-$ghostscript_min_version.tar.gz" -O "$tmp_ephemeral_dir/ghostscript/ghostscript.tar.gz"
    tar -zxvf "$tmp_ephemeral_dir/ghostscript/ghostscript.tar.gz" -C "$tmp_ephemeral_dir/ghostscript"

    # Compile
    pushd "$tmp_ephemeral_dir/ghostscript/ghostscript-$ghostscript_min_version"
    ./configure
    make
    sudo make install

    # Clean up
    popd
  else
    echo "gs is already the minimum required version ($ghostscript_min_version)"
  fi
}

remove() {
  sudo pip3 uninstall -y ocrmypdf

  sudo apt remove -y \
    bc \
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
