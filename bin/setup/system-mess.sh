#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-mess'
setup_module_desc='System-specific MESS initialization / configurations'

system_mess_dir="$retropie_system_config_dir/mess"

configure() {
  if has_emulator 'lr-mess'; then
    __configure_cfg_files
    __configure_ini_files
  fi
}

# Global configuration overrides
__configure_cfg_files() {
  mkdir -pv "$system_mess_dir/cfg"

  # Inputs/configs (global, system-specific)
  local config_dirname
  for config_dirname in 'config_dir' 'system_config_dir'; do
    each_path "{$config_dirname}/mess/cfg" find '{}' -name '*.cfg' -exec cp -v -t "$system_mess_dir/cfg/" '{}' +
  done
}

__configure_ini_files() {
  mkdir -pv "$system_mess_dir/ini"

  # MESS init (global, system-specific)
  local config_dirname
  for config_dirname in 'config_dir' 'system_config_dir'; do
    each_path "{$config_dirname}/mess/ini" find '{}' -name '*.ini' -exec cp -v -t "$system_mess_dir/ini/" '{}' +
  done
}

restore() {
  rm -rfv "$system_mess_dir"
}

setup "$1" "${@:3}"
