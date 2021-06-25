#!/bin/bash

install() {
  # Zip
  sudo apt install -y zip

  # XML processing
  sudo apt install -y python3-lxml

  if [ ! `command -v trrntzip` ] || [ ! -f /usr/local/etc/trrntzip.version ] || [ $(git ls-remote 'https://github.com/hydrogen18/trrntzip.git' HEAD | cut -f1) != $(cat /usr/local/etc/trrntzip.version) ]; then
    # Check out
    rm -rf '/tmp/trrntzip'
    git clone --depth 1 https://github.com/hydrogen18/trrntzip.git '/tmp/trrntzip'
    pushd '/tmp/trrntzip'
    trrntzip_version=$(git rev-parse HEAD)

    # Compile
    ./autogen.sh
    ./configure
    make
    sudo make install
    echo "$trrntzip_version" | sudo tee /usr/local/etc/trrntzip.version

    # Clean up
    popd
    rm -rf '/tmp/trrntzip'
  else
    echo "trrntzip is already the newest version ($(cat /usr/local/etc/trrntzip.version))"
  fi

  # CHDMan
  sudo apt install -y mame-tools

  # High-Performance HTTP
  sudo pip3 install pycurl
}

"${@}"
