#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_dir='/opt/retropie/supplementary/manualkit'

install() {
  sudo apt install -y libpoppler-cpp-dev
  sudo pip3 install -y python-poppler numpy keyboard

  sudo mkdir -p "$install_dir"
  sudo cp -v "$bin_dir/manualkit"/* "$install_dir/"

  export HOTKEY=$(setting '.manuals.hotkey')
  cat "$config_dir/manuals/triggerhappy.conf" | envsubst | sudo tee "$install_dir/triggerhappy.conf"
}

uninstall() {
  rm -rfv "$install_dir"
  sudo pip3 uninstall -y python-poppler nump
  sudo apt remove -y libpoppler-cpp-dev
}

"${@}"
