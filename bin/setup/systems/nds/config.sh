#!/bin/bash

system='nds'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/nds/config'
setup_module_desc='NDS emulator configuration'

config_file="$retropie_system_config_dir/drastic/config/drastic.cfg"

configure() {
  __restore_config
  ini_merge '{system_config_dir}/drastic.cfg' "$config_file" restore=false
}

restore() {
  __restore_config delete_src=true
}

__restore_config() {
  restore_partial_ini "$config_file" '^controls_' remove_source_matches=true "${@}"
}

setup "${@}"
