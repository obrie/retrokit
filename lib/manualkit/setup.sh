#!/bin/bash

set -e

target_mupdf_version=1.18.0
tmp_ephemeral_dir=$(mktemp -d)

# Clean up the ephemeral directory
trap 'rm -rf -- "$tmp_ephemeral_dir"' EXIT

_get_mupdf_version() {
  cat /usr/local/etc/mupdf.version 2>/dev/null || true
}

_set_mupdf_version() {
  echo "$target_mupdf_version" | sudo tee /usr/local/etc/mupdf.version
}

depends_mupdf() {
  if [ ! -f /usr/local/lib/libmupdf.a ] || [ "$(_get_mupdf_version)" != "$target_mupdf_version" ]; then
    # Ensure system version isn't installed
    sudo apt-get remove -y libmupdf-dev mupdf

    # System dependencies
    sudo apt-get install -y libfreetype6-dev
    sudo ln -fs /usr/include/freetype2/ft2build.h /usr/include/ft2build.h
    sudo ln -fs /usr/include/freetype2/freetype/ /usr/include/freetype

    # Download mupdf source
    local mupdf_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    wget "https://mupdf.com/downloads/archive/mupdf-$target_mupdf_version-source.tar.gz" -O "$mupdf_dir/mupdf.tar.gz"
    tar -zxvf "$mupdf_dir/mupdf.tar.gz" -C "$mupdf_dir"

    pushd "$mupdf_dir/mupdf-$target_mupdf_version-source"

    # Replace files in mupdf source
    wget "https://raw.githubusercontent.com/pymupdf/PyMuPDF/$target_mupdf_version/fitz/_config.h" -O include/mupdf/fitz/config.h

    # Compile and install
    export CFLAGS='-fPIC'
    export MAKEFLAGS='-j4'
    make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local
    sudo make HAVE_X11=no HAVE_GLFW=no HAVE_GLUT=no prefix=/usr/local install

    # Track mupdf version
    _set_mupdf_version

    popd
  fi
}

depends() {
  # There's no wheel available for 32-bit raspbian and the version of mupdf
  # available via apt is too old.  As a result, we need to build from source.
  depends_mupdf

  # TODO: Add dependency on devicekit here

  # Python libs
  sudo pip3 install \
    psutil~=5.8 \
    PyMuPDF==1.18.15
}

remove() {
  sudo pip3 uninstall -y psutil PyMuPDF
}

"${@}"
