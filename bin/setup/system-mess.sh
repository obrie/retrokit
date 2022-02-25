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

  # Inputs/configs across multiple MESS systems
  if [ -d "$config_dir/mess/cfg/" ]; then
    cp -Rv "$config_dir"/mess/cfg/* "$system_mess_dir/cfg/"
  fi

  # System-specific inputs/configs
  if [ -d "$system_config_dir/mess/cfg" ]; then
    cp -Rv "$system_config_dir"/mess/cfg/* "$system_mess_dir/cfg/"
  fi
}

__configure_ini_files() {
  mkdir -pv "$system_mess_dir/ini"

  # Init setup across multiple MESS systems
  if [ -d "$config_dir/mess/ini" ]; then
    cp -Rv "$config_dir"/mess/ini/* "$system_mess_dir/ini/"
  fi

  # System-specific MESS init
  if [ -d "$system_config_dir/mess/ini" ]; then
    cp -Rv "$system_config_dir"/mess/ini/* "$system_mess_dir/ini/"
  fi
}

restore() {
  rm -rfv "$system_mess_dir"
}

setup "$1" "${@:3}"
