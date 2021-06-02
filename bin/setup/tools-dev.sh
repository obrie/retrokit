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
  if [ ! `command -v raspi2png` ] || has_newer_commit https://github.com/AndrewFromMelbourne/raspi2png "$(cat /etc/raspi2png.version || true)"; then
    # Check out
    rm -rf "$tmp_dir/raspi2png"
    git clone --depth 1 https://github.com/AndrewFromMelbourne/raspi2png.git "$tmp_dir/raspi2png"
    pushd "$tmp_dir/raspi2png"
    local version=$(git rev-parse HEAD)

    # Compile
    make
    sudo make install
    echo "$version" | sudo tee /etc/raspi2png.version

    # Clean up
    popd
    rm -rf "$tmp_dir/raspi2png"
  else
    echo 'raspi2png is already installed'
  fi
}

uninstall() {
  sudo rm -f /usr/bin/raspi2png /etc/raspi2png.version
  sudo apt remove -y mesa-utils screen sysbench
}

"${@}"
