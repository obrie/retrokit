#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_from_source() {
  # We need to install a newer version of chdman for it to work with
  # Dreamcast redump images.  This won't be needed once we're on bullseye.
  sudo apt install -y libfontconfig1-dev qt5-default libsdl2-ttf-dev libxinerama-dev libxi-dev

  # Build from source
  git clone https://github.com/mamedev/mame "$tmp_dir/mame"
  pushd "$tmp_dir/mame"
  git checkout mame0230
  make NOWERROR=1 ARCHOPTS=-U_FORTIFY_SOURCE PYTHON_EXECUTABLE=python3 TOOLS=1 REGENIE=1

  # Install chdman
  sudo cp castool chdman floptool imgtool jedutil ldresample ldverify romcmp /usr/local/bin/
  popd
  rm -rf "$tmp_dir/mame"
}

install_from_binary() {
  sudo unzip "$app_dir/cache/mame/mame0223-tools.zip" -d /usr/local/bin/
}

install() {
  install_from_binary
}

uninstall() {
  sudo rm \
    /usr/local/bin/castool \
    /usr/local/bin/chdman \
    /usr/local/bin/floptool \
    /usr/local/bin/imgtool \
    /usr/local/bin/jedutil \
    /usr/local/bin/ldresample \
    /usr/local/bin/ldverify \
    /usr/local/bin/romcmp
}

"${@}"
