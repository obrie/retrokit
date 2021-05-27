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
  # Location of the global file for defaults
  local global_core_options_path='/opt/retropie/configs/all/retroarch-core-options.cfg'

  # Figure out where the core options live for this system
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null || true)
  if [ -n "$core_options_path" ]; then
    # Use the global defaults as the initial file
    cp "$global_core_options_path" "$core_options_path"
    crudini --merge "$core_options_path" < "$system_config_dir/retroarch-core-options.cfg"
  else
    ini_merge "$system_config_dir/retroarch-core-options.cfg" "$global_core_options_path" restore=false
  fi
}

install() {
  install_config
  install_emulator_config
  install_core_options
}

uninstall() {
  # Remove system-specific retroarch core options files
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null || true)
  if [ -n "$core_options_path" ]; then
    rm -f "$core_options_path"
  fi

  # Restore emulator-specific retroarch configs
  while IFS="$tab" read library_name; do
    restore "$retroarch_config_dir/config/$library_name/$library_name.cfg" delete_src=true
  done < <(system_setting 'select(.emulators) | .emulators | to_entries[] | select(.value.library_name) | .value.library_name')

  # Restore system-specific retroarch config
  restore "$retropie_system_config_dir/retroarch.cfg"
}

"$1" "${@:3}"
