#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='tools-psp'
setup_module_desc='PSP tools for managing CSO files'

depends() {
  # Install dependencies
  sudo apt-get install -y liblz4-dev libdeflate-dev libuv1-dev
}

build() {
  local maxcso_version="$(cat /usr/local/etc/maxcso.version 2>/dev/null || true)"
  if [ ! `command -v maxcso` ] || has_newer_commit https://github.com/unknownbrackets/maxcso "$maxcso_version"; then
    # Check out
    local maxcso_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    git clone --depth 1 https://github.com/unknownbrackets/maxcso "$maxcso_dir"
    pushd "$maxcso_dir"
    maxcso_version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$maxcso_version" | sudo tee /usr/local/etc/maxcso.version

    # Clean up
    popd
  else
    echo "maxcso is already the newest version ($maxcso_version)"
  fi
}

remove() {
  sudo rm -fv /usr/local/bin/maxcso /usr/local/share/man/man1/maxcso.1 /usr/local/etc/maxcso.version
  sudo apt-get remove -y liblz4-dev libdeflate-dev libuv1-dev
}

setup "${@}"
