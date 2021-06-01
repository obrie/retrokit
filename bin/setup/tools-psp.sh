#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install dependencies
  sudo apt install -y liblz4-dev libdeflate-dev libuv1-dev

  if [ ! `command -v maxcso` ]; then
    # Check out
    rm -rf "$tmp_dir/maxcso"
    git clone --depth 1 https://github.com/unknownbrackets/maxcso "$tmp_dir/maxcso"
    pushd "$tmp_dir/maxcso"

    # Compile
    make
    sudo make install

    # Clean up
    popd
    rm -rf "$tmp_dir/maxcso"
  else
    echo 'Already installed maxcso'
  fi
}

uninstall() {
  sudo rm -f /usr/local/bin/maxcso
  sudo rm -f /usr/local/share/man/man1/maxcso.1

  sudo apt remove -y liblz4-dev libdeflate-dev libuv1-dev
}

"${@}"
