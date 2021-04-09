#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # XML processing
  sudo apt install -y python3-lxml

  # TorrentZip
  if [ ! `command -v trrntzip` ]; then
    mkdir $tmp_dir/trrntzip
    git clone https://github.com/hydrogen18/trrntzip.git $tmp_dir/trrntzip
    pushd $tmp_dir/trrntzip
    ./autogen.sh
    ./configure
    make
    sudo make install
    popd
    rm -rf $tmp_dir/trrntzip
  fi

  # CHDMan
  sudo apt install -y mame-tools
}

uninstall() {
  sudo apt remove -y mame-tools python3-xml
  sudo rm /usr/local/bin/trrntzip
}

"${@}"
