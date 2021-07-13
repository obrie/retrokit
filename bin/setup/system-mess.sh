#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

system_mess_dir="$retropie_system_config_dir/mess"

# Global configuration overrides
install_cfg_files() {
  mkdir -pv "$system_mess_dir/cfg"

  if [ -d "$config_dir/mess/cfg/" ]; then
    cp -Rv "$config_dir"/mess/cfg/* "$system_mess_dir/cfg/"
  fi

  if [ -d "$system_config_dir/mess/cfg" ]; then
    cp -Rv "$system_config_dir"/mess/cfg/* "$system_mess_dir/cfg/"
  fi
}

install_ini_files() {
  mkdir -pv "$system_mess_dir/ini"

  if [ -d "$config_dir/mess/ini" ]; then
    cp -Rv "$config_dir"/mess/ini/* "$system_mess_dir/ini/"
  fi

  if [ -d "$system_config_dir/mess/ini" ]; then
    cp -Rv "$system_config_dir"/mess/ini/* "$system_mess_dir/ini/"
  fi
}

install() {
  if has_emulator 'lr-mess'; then
    install_cfg_files
    install_ini_files
  fi
}

uninstall() {
  rm -rfv "$system_mess_dir"
}

"$1" "${@:3}"
