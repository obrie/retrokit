#!/bin/bash

system='psp'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/psp/controllers'
setup_module_desc='PSP controller overrides'
setup_module_reconfigure_after_update=true

after_retropie_reconfigure() {
  rm -fv '/opt/retropie/emulators/ppsspp/assets/gamecontrollerdb.txt.rk-src'
  configure
}

configure() {
  backup_and_restore '/opt/retropie/emulators/ppsspp/assets/gamecontrollerdb.txt' as_sudo=true
  each_path '{config_dir}/controllers/gamecontrollerdb.local.txt' cat '{}' | uniq | sudo tee -a /opt/retropie/emulators/ppsspp/assets/gamecontrollerdb.txt >/dev/null
}

restore() {
  restore_file '/opt/retropie/emulators/ppsspp/assets/gamecontrollerdb.txt' delete_src=true
}

setup "${@}"
