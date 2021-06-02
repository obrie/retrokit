#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Install dependencies
  sudo apt install -y liblz4-dev libdeflate-dev libuv1-dev

  if [ ! `command -v maxcso` ] || has_newer_commit https://github.com/unknownbrackets/maxcso "$(cat /usr/local/etc/maxcso.version || true)"; then
    # Check out
    rm -rf "$tmp_dir/maxcso"
    git clone --depth 1 https://github.com/unknownbrackets/maxcso "$tmp_dir/maxcso"
    pushd "$tmp_dir/maxcso"
    local version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$version" | sudo tee /usr/local/etc/maxcso.version

    # Clean up
    popd
    rm -rf "$tmp_dir/maxcso"
  else
    echo 'maxcso is already latest version'
  fi
}

uninstall() {
  sudo rm -f /usr/local/bin/maxcso /usr/local/share/man/man1/maxcso.1 /usr/local/etc/maxcso.version
  sudo apt remove -y liblz4-dev libdeflate-dev libuv1-dev
}

"${@}"
