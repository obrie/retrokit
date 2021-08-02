#!/bin/bash

install_mupdf() {
  version=1.18.0

  local current_mupdf_version="$(cat /etc/mupdf.version 2>/dev/null || true)"
  if [ ! -f /usr/local/lib/libmupdf.a ] || [ "$current_mupdf_version" != "$version" ]; then
    # Ensure system version isn't installed
    sudo apt remove -y libmupdf-dev mupdf

    # System dependencies
    sudo apt install -y libfreetype6-dev
    sudo ln -s /usr/include/freetype2/ft2build.h /usr/include/ft2build.h
    sudo ln -s /usr/include/freetype2/freetype/ /usr/include/freetype

    # Download mupdf source
    rm -rf "$tmp_dir/mupdf"
    mkdir "$tmp_dir/mupdf"
    wget "https://mupdf.com/downloads/archive/mupdf-$version-source.tar.gz" -O "$tmp_dir/mupdf/mupdf.tar.gz"
    tar -zxvf "$tmp_dir/mupdf/mupdf.tar.gz" -C "$tmp_dir/mupdf"

    pushd "$tmp_dir/mupdf/mupdf-$version-source"

    # Replace files in mupdf source
    wget "https://raw.githubusercontent.com/pymupdf/PyMuPDF/$version/fitz/_config.h" -O include/mupdf/fitz/config.h

    # Compile and install
    export CFLAGS='-fPIC'
    make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local
    sudo make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local install

    popd
    rm -rf "$tmp_dir/mupdf"
  fi
}

install() {
  # Python libs
  sudo pip3 install evdev==1.4.0 pyudev==0.22.0 psutil==5.8.0

  # There's no wheel available for 32-bit raspbian and the version of mupdf
  # available via apt is too old.  As a result, we need to build from source.
  install_mupdf

  sudo pip3 install PyMuPDF==1.18.15
}

"${@}"
