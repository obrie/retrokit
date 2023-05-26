#!/bin/bash

all_depends() {
  depends
  gamefile_depends
}

depends() {
  sudo pip3 install -r requirements.txt
}

gamefile_depends() {
  # Zip
  sudo apt-get install -y zip

  # CHDMan
  sudo apt-get install -y mame-tools

  # Torrentzip
  __depends_trrntzip
}

__depends_trrntzip() {
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
}

remove() {
  sudo apt-get remove -y zip mame-tools
  sudo apt-get autoremove --purge -y
  [ -z $(command -v pip3) ] || sudo pip3 uninstall -y -r requirements.txt
  sudo rm -fv /usr/local/bin/trrntzip /usr/local/etc/trrntzip.version
}

"${@}"
