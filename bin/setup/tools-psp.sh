#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install dependencies
  sudo apt install -y liblz4-dev libdeflate-dev libuv1-dev

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
}

uninstall() {
  sudo rm -f /usr/local/bin/maxcso
  sudo rm -f /usr/local/share/man/man1/maxcso.1
}

"${@}"
