#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Global configuration overrides
install_config() {
  ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
}

install_emulator_config() {
  while IFS="$tab" read library_name; do
    ini_merge "$system_config_dir/retroarch/$library_name/$library_name.cfg" "$retroarch_config_dir/config/$library_name/$library_name.cfg"
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | select(.value.library_name) | .value.library_name')
}

# Global core options
install_core_options() {
  # Figure out where the core options live for this system
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null || true)
  local restore=true
  if [ -z "$core_options_path" ]; then
    core_options_path='/opt/retropie/configs/all/retroarch-core-options.cfg'
    restore=false
  fi

  # Don't restore if this is the global retroarch-core-options.cfg we're merging into
  ini_merge "$system_config_dir/retroarch-core-options.cfg" "$core_options_path" restore=$restore
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
