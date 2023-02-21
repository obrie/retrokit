#!/bin/bash

system='daphne'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/daphne/actionmax-crosshair'
setup_module_desc='Crosshair overrides for ActionMax emulation'

configure() {
  if [ -d "$roms_dir/daphne/actionmax" ]; then
    file_cp '{system_config_dir}/actionmax/sprite_crosshair.png' "$roms_dir/daphne/actionmax/sprite_crosshair.png"
  fi
}

restore() {
  restore_file "$roms_dir/daphne/actionmax/sprite_crosshair.png" delete_src=true
}

setup "${@}"
