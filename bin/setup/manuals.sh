#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_dir='/opt/retropie/supplementary/manualkit'

install() {
  sudo apt install -y ghostscript

  sudo mkdir -p "$install_dir"
  sudo cp -v "$bin_dir/manualkit/manualkit.sh" "$install_dir/"

  export HOTKEY=$(setting '.manuals.hotkey')
  cat "$config_dir/manuals/triggerhappy.conf" | envsubst | sudo tee "$install_dir/triggerhappy.conf"
}

uninstall() {
  rm -rfv "$install_dir"
  sudo apt remove -y ghostscript
}

"${@}"
