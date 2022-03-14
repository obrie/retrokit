#!/bin/bash

system='n64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/n64/config'
setup_module_desc='N64 emulator configuration'

configure() {
  ini_merge "$system_config_dir/GLideN64.custom.ini" "$retropie_system_config_dir/GLideN64.custom.ini"
  ini_merge "$system_config_dir/mupen64plus.cfg" "$retropie_system_config_dir/mupen64plus.cfg"
}

restore() {
  restore_file "$retropie_system_config_dir/mupen64plus.cfg" delete_src=true
  restore_file "$retropie_system_config_dir/GLideN64.custom.ini" delete_src=true
}

setup "${@}"
