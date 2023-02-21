#!/bin/bash

system='n64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/n64/config'
setup_module_desc='N64 emulator configuration'
setup_module_reconfigure_after_update=true

configure() {
  __restore_mupen64plus_gliden64
  ini_merge '{system_config_dir}/GLideN64.custom.ini' "$retropie_system_config_dir/GLideN64.custom.ini" backup=false
  ini_merge '{system_config_dir}/mupen64plus.cfg' "$retropie_system_config_dir/mupen64plus.cfg"
}

restore() {
  __restore_mupen64plus_gliden64
  restore_file "$retropie_system_config_dir/mupen64plus.cfg" delete_src=true
}

__restore_mupen64plus_gliden64() {
  # This file comes directly from the install, so we always use it as the base
  cp -v "$retropie_emulators_dir/mupen64plus/share/mupen64plus/GLideN64.custom.ini" "$retropie_system_config_dir/GLideN64.custom.ini"
}

setup "${@}"
