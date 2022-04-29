#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='retropie-settings'
setup_module_desc='RetroPie global settings'

configure() {
  __configure_autostart
}

__configure_autostart() {
  file_cp '{config_dir}/retropie/autostart.sh' '/opt/retropie/configs/all/autostart.sh' envsubst=false
}

restore() {
  __restore_autostart
}

__restore_autostart() {
  restore_file '/opt/retropie/configs/all/autostart.sh' delete_src=true
}

setup "${@}"
