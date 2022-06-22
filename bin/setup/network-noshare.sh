#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='network-noshare'
setup_module_desc='Disable Samba network sharing'

configure() {
  sudo update-rc.d nmbd disable
  sudo update-rc.d smbd disable
}

restore() {
  sudo update-rc.d nmbd enable
  sudo update-rc.d smbd enable
}

setup "${@}"
