#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

system_mess_dir="$retropie_system_config_dir/mess"

install() {
  if has_emulator 'lr-mess'; then
    __install_cfg_files
    __install_ini_files
  fi
}

# Global configuration overrides
__install_cfg_files() {
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

__install_ini_files() {
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

uninstall() {
  rm -rfv "$system_mess_dir"
}

"$1" "${@:3}"
