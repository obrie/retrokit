#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  sudo cp -R $config_dir/bluetooth/* /var/lib/bluetooth/
}

uninstall() {
  echo 'Uninstall skipped for bluetooth'
}

"${@}"
