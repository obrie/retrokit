#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_dir='/opt/retropie/supplementary/manualkit'

install() {
  "$bin_dir/manualkit/setup.sh" install

  sudo mkdir -p "$install_dir"
  sudo rsync -av "$bin_dir/manualkit/" "$install_dir/" --delete

  cp -v "$config_dir/manuals/manualkit.conf" '/opt/retropie/configs/all/manualkit.conf'

  sudo apt install -y enscript
}

uninstall() {
  rm -rfv "$install_dir" '/opt/retropie/configs/all/manualkit.conf'
  sudo pip3 uninstall -y evdev pyudev psutil PyMuPDF
  sudo apt remove -y enscript
}

"${@}"
