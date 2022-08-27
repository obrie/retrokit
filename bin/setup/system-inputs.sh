#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-inputs'
setup_module_desc='System-specific automatic port selection using autoport'

configure() {
  restore
  ini_merge '{system_config_dir}/autoport.cfg' "$retropie_system_config_dir/autoport.cfg" backup=false overwrite=true
}

restore() {
  rm -rfv "$retropie_system_config_dir/autoport.cfg"
}

setup "$1" "${@:3}"
