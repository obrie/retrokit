#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Benchmarking
  sudo apt install -y sysbench

  # Screen
  sudo apt install -y screen
  
  # Graphics
  sudo apt install -y mesa-utils

  # Screenshots
  local raspi2png_version="$(cat /etc/raspi2png.version 2>/dev/null || true)"
  if [ ! `command -v raspi2png` ] || has_newer_commit https://github.com/AndrewFromMelbourne/raspi2png "$raspi2png_version"; then
    # Check out
    rm -rf "$tmp_ephemeral_dir/raspi2png"
    git clone --depth 1 https://github.com/AndrewFromMelbourne/raspi2png.git "$tmp_ephemeral_dir/raspi2png"
    pushd "$tmp_ephemeral_dir/raspi2png"
    raspi2png_version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$raspi2png_version" | sudo tee /etc/raspi2png.version

    # Clean up
    popd
    rm -rf "$tmp_ephemeral_dir/raspi2png"
  else
    echo "raspi2png is already the newest version ($raspi2png_version)"
  fi
}

uninstall() {
  sudo rm -fv /usr/bin/raspi2png /etc/raspi2png.version
  sudo apt remove -y mesa-utils screen sysbench
}

"${@}"
