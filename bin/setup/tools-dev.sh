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
  if [ ! `command -v raspi2png` ]; then
    mkdir "$tmp_dir/raspi2png"
    git clone --depth 1 https://github.com/AndrewFromMelbourne/raspi2png.git "$tmp_dir/raspi2png"
    pushd "$tmp_dir/raspi2png"
    make
    sudo make install
    popd
    rm -rf "$tmp_dir/raspi2png"
  fi
}

uninstall() {
  sudo rm -f /usr/bin/raspi2png
  sudo apt remove -y mesa-utils screen sysbench
}

"${@}"
