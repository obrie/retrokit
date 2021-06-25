#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  "$bin_dir/romkit/setup.sh" install
}

uninstall() {
  sudo apt remove -y mame-tools python3-lxml zip
  sudo pip3 uninstall -y pycurl
  sudo rm -fv /usr/local/bin/trrntzip /usr/local/etc/trrntzip.version
}

"${@}"
