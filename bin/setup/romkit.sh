#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Zip
  sudo apt install -y zip

  # XML processing
  sudo apt install -y python3-lxml

  # TorrentZip
  if [ ! `command -v trrntzip` ] || has_newer_commit https://github.com/hydrogen18/trrntzip.git "$(cat /usr/local/etc/trrntzip.version || true)"; then
    # Check out
    rm -rf "$tmp_dir/trrntzip"
    git clone --depth 1 https://github.com/hydrogen18/trrntzip.git "$tmp_dir/trrntzip"
    pushd "$tmp_dir/trrntzip"
    local version=$(git rev-parse HEAD)

    # Compile
    ./autogen.sh
    ./configure
    make
    sudo make install
    echo "$version" | sudo tee /usr/local/etc/trrntzip.version

    # Clean up
    popd
    rm -rf "$tmp_dir/trrntzip"
  else
    echo 'trrntzip is already latest version'
  fi

  # CHDMan
  sudo apt install -y mame-tools
}

uninstall() {
  sudo apt remove -y mame-tools python3-lxml zip
  sudo rm -f /usr/local/bin/trrntzip /usr/local/etc/trrntzip.version
}

"${@}"
