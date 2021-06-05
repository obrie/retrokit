#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Global configuration overrides
install_config() {
  ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
}

install_emulator_config() {
  while IFS="$tab" read library_name; do
    ini_merge "$system_config_dir/retroarch/$library_name/$library_name.cfg" "$retroarch_config_dir/config/$library_name/$library_name.cfg"
  done < <(system_setting 'select(.emulators) | .emulators[] | select(.library_name) | .library_name')
}

# Global core options
install_core_options() {
  # Location of the global file for defaults
  local global_core_options_path='/opt/retropie/configs/all/retroarch-core-options.cfg'

  # Figure out where the core options live for this system
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null | tr -d '"' || true)
  if [ -n "$core_options_path" ]; then
    # Use the global defaults as the initial file
    cp -v "$global_core_options_path" "$core_options_path"

    if [ -f "$system_config_dir/retroarch-core-options.cfg" ]; then
      echo "Merging ini $system_config_dir/retroarch-core-options.cfg to $core_options_path"
      crudini --merge "$core_options_path" < "$system_config_dir/retroarch-core-options.cfg"
    fi
  else
    ini_merge "$system_config_dir/retroarch-core-options.cfg" "$global_core_options_path" restore=false
  fi
}

install() {
  install_config
  install_emulator_config
  install_core_options

  # Reinstall the game-specific retroarch core options for this system.
  # Yes, this might mean we install game-specific core options multiple
  # times, but it also means we don't have to worry about remembering to
  # re-run system-roms-retroarch after running this setupmodule
  if [ $(setting ".setup | has(\"system-roms-retroarch\")") == 'true' ]; then
    "$bin_dir/setup.sh" install_retroarch_core_options system-roms-retroarch "$system"
  fi
}

uninstall() {
  # Remove system-specific retroarch core options files
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null | tr -d '"' || true)
  if [ -n "$core_options_path" ]; then
    rm -fv "$core_options_path"
  fi

  # Restore emulator-specific retroarch configs
  while IFS="$tab" read library_name; do
    restore "$retroarch_config_dir/config/$library_name/$library_name.cfg" delete_src=true
  done < <(system_setting 'select(.emulators) | .emulators[] | select(.library_name) | .library_name')

  # Restore system-specific retroarch config
  restore "$retropie_system_config_dir/retroarch.cfg"
}

"$1" "${@:3}"
