#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='romkit'
setup_module_desc='romkit installation for filtering / managing ROMs'

depends() {
  # Romkit requirements (explicitly not installing everything
  # like chdman)
  sudo apt-get install -y zip
  sudo pip3 install lxml~=4.9 pycurl~=7.45
  "$lib_dir/romkit/setup.sh" __depends_trrntzip
}

remove() {
  sudo apt-get remove -y zip
  sudo apt-get autoremove --purge -y
  sudo pip3 uninstall -y lxml pycurl
  sudo rm -fv /usr/local/bin/trrntzip /usr/local/etc/trrntzip.version
}

setup "${@}"
