#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-autostart'
setup_module_desc='RetroPie autostart hook extensions'

build() {
  file_cp '{ext_dir}/autostart/autostart.sh' '/opt/retropie/configs/all/autostart.sh' envsubst=false
}

configure() {
  file_cp '{config_dir}/autostart/autostart-launch.sh' '/opt/retropie/configs/all/autostart-launch.sh' envsubst=false backup=false
}

restore() {
  rm -fv /opt/retropie/configs/all/autostart-launch.sh
}

remove() {
  restore_file '/opt/retropie/configs/all/autostart.sh' delete_src=true
}

setup "${@}"
