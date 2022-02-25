#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='romkit'
setup_module_desc='romkit installation for filtering / managing ROMs'

depends() {
  # Romkit requirements (explicitly not installing everything
  # like chdman)
  sudo apt install -y zip
  sudo pip3 install lxml pycurl
  "$bin_dir/romkit/setup.sh" __depends_trrntzip
}

remove() {
  sudo apt remove -y zip
  sudo pip3 uninstall -y lxml pycurl
  sudo rm -fv /usr/local/bin/trrntzip /usr/local/etc/trrntzip.version

setup "${@}"
