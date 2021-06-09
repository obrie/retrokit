#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

install() {
  # Back up bluetooth settings
  if [ ! -d '/var/lib/bluetooth.rk-src' ]; then
    sudo cp -av /var/lib/bluetooth /var/lib/bluetooth.rk-src
  fi

  sudo ~/RetroPie-Setup/retropie_packages.sh bluetooth gui
}

uninstall() {
  sudo ~/RetroPie-Setup/retropie_packages.sh bluetooth gui
  sudo rm -rfv /var/lib/bluetooth.rk-src
}

"${@}"
