#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='tools-dev'
setup_module_desc='Common tools useful for testing and development'

depends() {
  # Screen
  sudo apt-get install -y screen
  
  # Graphics
  sudo apt-get install -y mesa-utils

  # Screenshots
  local raspi2png_version="$(cat /etc/raspi2png.version 2>/dev/null || true)"
  if [ ! `command -v raspi2png` ] || has_newer_commit https://github.com/AndrewFromMelbourne/raspi2png "$raspi2png_version"; then
    # Check out
    local raspi2png_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
    git clone --depth 1 https://github.com/AndrewFromMelbourne/raspi2png.git "$raspi2png_dir"
    pushd "$raspi2png_dir"
    raspi2png_version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$raspi2png_version" | sudo tee /etc/raspi2png.version

    # Clean up
    popd
  else
    echo "raspi2png is already the newest version ($raspi2png_version)"
  fi
}

remove() {
  sudo rm -fv /usr/bin/raspi2png /etc/raspi2png.version
  sudo apt-get remove -y mesa-utils screen
}

setup "${@}"
