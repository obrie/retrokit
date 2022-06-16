#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../common.sh"

setup_module_id='hardware/bluetooth-pair'
setup_module_desc='Bluetooth pairing configuration'

configure() {
  if [ "$NONINTERACTIVE" != 'true' ]; then
    sudo $HOME/RetroPie-Setup/retropie_packages.sh bluetooth gui
  fi
}

setup "${@}"
