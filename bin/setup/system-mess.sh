#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-mess'
setup_module_desc='System-specific MESS initialization / configurations'

system_mame_dir="$retropie_system_config_dir/mame"

configure() {
  if has_emulator 'lr-mess'; then
    restore
  
    __configure_cfg_files
    __configure_ini_files
  fi
}

# Global configuration overrides
__configure_cfg_files() {
  mkdir -pv "$system_mame_dir/cfg"

  # Inputs/configs (global, system-specific)
  each_path "{config_dir}/mess/cfg" find '{}' -name '*.cfg' -exec cp -v -t "$system_mame_dir/cfg/" '{}' +
  each_path "{system_config_dir}/mame/cfg" find '{}' -name '*.cfg' -exec cp -v -t "$system_mame_dir/cfg/" '{}' +
}

__configure_ini_files() {
  mkdir -pv "$system_mame_dir/ini"

  # MESS init (global, system-specific)
  each_path "{config_dir}/mess/ini" find '{}' -name '*.ini' -exec cp -v -t "$system_mame_dir/ini/" '{}' +
  each_path "{system_config_dir}/mame/ini" find '{}' -name '*.ini' -exec cp -v -t "$system_mame_dir/ini/" '{}' +
}

restore() {
  rm -rfv \
    "$system_mame_dir/cfg" \
    "$system_mame_dir/ini"
}

setup "${@}"
