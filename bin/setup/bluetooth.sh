#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install_pairings() {
  # Back up bluetooth settings
  if [ ! -d '/var/lib/bluetooth.rk-src' ]; then
    sudo cp -R /var/lib/bluetooth/ /var/lib/bluetooth.rk-src
  fi

  sudo cp -R $config_dir/bluetooth/* /var/lib/bluetooth/
}

# Fix ghost inputs on initial connection
# See: https://retropie.org.uk/docs/Bluetooth-Controller/
fix_ghost_inputs() {
  backup_and_restore /usr/bin/btuart as_sudo=true
  sudo sed -i 's/bcm43xx 921600/bcm43xx 115200/g'
}

install() {
  install_pairings
  fix_ghost_inputs
}

uninstall() {
  restore /usr/bin/btuart
}

"${@}"
