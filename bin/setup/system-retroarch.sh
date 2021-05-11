#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Global configuration overrides
install_config() {
  local config_path="$system_config_dir/retroarch.cfg"
  if [ -f "$config_path" ]; then
    ini_merge "$config_path" "$retropie_system_config_dir/retroarch.cfg"
  fi
}

install_emulator_config() {
  while IFS="$tab" read library_name; do
    local config_path="$system_config_dir/retroarch/$library_name/$library_name.cfg"
    if [ -f "$config_path" ]; then
      ini_merge "$config_path" "$retroarch_config_dir/config/$library_name/$library_name.cfg"
    fi
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | select(.value.library_name) | .value.library_name')
}

# Global core options
install_core_options() {
  local config_path="$system_config_dir/retroarch-core-options.cfg"
  if [ -f "$config_path" ]; then
    # Don't restore since it'll be written to by multiple systems
    ini_merge "$config_path" '/opt/retropie/configs/all/retroarch-core-options.cfg' restore=false
  fi
}

install() {
  install_config
  install_emulator_config
  install_core_options
}

uninstall() {
  restore "$retropie_system_config_dir/retroarch.cfg"
}

"$1" "${@:3}"
