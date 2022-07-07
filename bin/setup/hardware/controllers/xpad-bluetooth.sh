#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../../common.sh"

setup_module_id='hardware/controllers/xpad-bluetooth'
setup_module_desc='Xbox bluetooth controller setup and configuration'

build() {
  install_retropie_package 'supplementary' 'xpadneo-plus' 'source'
}

remove() {
  uninstall_retropie_package 'xpadneo-plus'
}

setup "${@}"
