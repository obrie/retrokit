#!/bin/bash

system='psp'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/psp/controllers'
setup_module_desc='PSP controller overrides'
setup_module_reconfigure_after_update=true

ppsspp_dir="$retropie_emulators_dir/ppsspp"

after_retropie_reconfigure() {
  rm -fv "$ppsspp_dir/assets/gamecontrollerdb.txt.rk-src"
  configure
}

configure() {
  backup_and_restore "$ppsspp_dir/assets/gamecontrollerdb.txt" as_sudo=true
  each_path '{config_dir}/controllers/gamecontrollerdb.local.txt' cat '{}' | uniq | sudo tee -a "$ppsspp_dir/assets/gamecontrollerdb.txt" >/dev/null
}

restore() {
  restore_file "$ppsspp_dir/assets/gamecontrollerdb.txt" as_sudo=true delete_src=true
}

setup "${@}"
