#!/bin/bash

system='psp'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/psp/config'
setup_module_desc='PSP configuration overrides'

configure() {
  ini_merge '{system_config_dir}/controls.ini' "$retropie_system_config_dir/PSP/SYSTEM/controls.ini"
  ini_merge '{system_config_dir}/ppsspp.ini' "$retropie_system_config_dir/PSP/SYSTEM/ppsspp.ini"
}

restore() {
  restore_file "$retropie_system_config_dir/PSP/SYSTEM/controls.ini" delete_src=true
  restore_file "$retropie_system_config_dir/PSP/SYSTEM/ppsspp.ini" delete_src=true
}

setup "${@}"
