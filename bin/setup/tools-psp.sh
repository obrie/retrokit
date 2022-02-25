#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='tools-psp'
setup_module_desc='PSP tools for managing CSO files'

depends() {
  # Install dependencies
  sudo apt install -y liblz4-dev libdeflate-dev libuv1-dev

  local maxcso_version="$(cat /usr/local/etc/maxcso.version 2>/dev/null || true)"
  if [ ! `command -v maxcso` ] || has_newer_commit https://github.com/unknownbrackets/maxcso "$maxcso_version"; then
    # Check out
    rm -rf "$tmp_ephemeral_dir/maxcso"
    git clone --depth 1 https://github.com/unknownbrackets/maxcso "$tmp_ephemeral_dir/maxcso"
    pushd "$tmp_ephemeral_dir/maxcso"
    maxcso_version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$maxcso_version" | sudo tee /usr/local/etc/maxcso.version

    # Clean up
    popd
    rm -rf "$tmp_ephemeral_dir/maxcso"
  else
    echo "maxcso is already the newest version ($maxcso_version)"
  fi
}

remove() {
  sudo rm -fv /usr/local/bin/maxcso /usr/local/share/man/man1/maxcso.1 /usr/local/etc/maxcso.version
  sudo apt remove -y liblz4-dev libdeflate-dev libuv1-dev
}

setup "${@}"
