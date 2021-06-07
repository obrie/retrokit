#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Zip
  sudo apt install -y zip

  # XML processing
  sudo apt install -y python3-lxml

  # TorrentZip
  local trrntzip_version="$(cat /usr/local/etc/trrntzip.version 2>/dev/null || true)"
  if [ ! `command -v trrntzip` ] || has_newer_commit https://github.com/hydrogen18/trrntzip.git "$trrntzip_version"; then
    # Check out
    rm -rf "$tmp_dir/trrntzip"
    git clone --depth 1 https://github.com/hydrogen18/trrntzip.git "$tmp_dir/trrntzip"
    pushd "$tmp_dir/trrntzip"
    trrntzip_version=$(git rev-parse HEAD)

    # Compile
    ./autogen.sh
    ./configure
    make
    sudo make install
    echo "$trrntzip_version" | sudo tee /usr/local/etc/trrntzip.version

    # Clean up
    popd
    rm -rf "$tmp_dir/trrntzip"
  else
    echo "trrntzip is already the newest version ($trrntzip_version)"
  fi

  # CHDMan
  sudo apt install -y mame-tools
}

uninstall() {
  sudo apt remove -y mame-tools python3-lxml zip
  sudo rm -fv /usr/local/bin/trrntzip /usr/local/etc/trrntzip.version
}

"${@}"
