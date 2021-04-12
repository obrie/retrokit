#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  # Back up bluetooth settings
  if [ ! -d '/var/lib/bluetooth.orig' ]; then
    sudo cp -R /var/lib/bluetooth/ /var/lib/bluetooth.orig
  fi

  sudo cp -R $config_dir/bluetooth/* /var/lib/bluetooth/
}

uninstall() {
  echo 'Uninstall skipped for bluetooth'
}

"${@}"
