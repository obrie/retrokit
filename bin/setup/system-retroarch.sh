#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# System-specific configuration overrides
install_config() {
  if [ -f "$system_config_dir/retroarch.cfg" ]; then
    ini_merge "$system_config_dir/retroarch.cfg" "$retropie_system_config_dir/retroarch.cfg"
  fi
}

# Global core options
install_global_core_options() {
  if [ -f "$system_config_dir/retroarch-core-options.cfg" ]; then
    # Don't restore since it'll be written to by multiple systems
    ini_merge "$system_config_dir/retroarch-core-options.cfg" '/opt/retropie/configs/all/retroarch-core-options.cfg' restore=false
  fi
}

# Game-specific core options
install_game_core_options() {
  if [ -d "$system_config_dir/retroarch_opts" ]; then
    while read library_name core_name; do
      # Retroarch emulator-specific config
      local retroarch_emulator_config_dir="$retroarch_config_dir/config/$library_name"
      mkdir -p "$retroarch_emulator_config_dir"

      # Core Options overides (https://retropie.org.uk/docs/RetroArch-Core-Options/)
      find "$system_config_dir/retroarch_opts" -iname "*.opt" | while read override_file; do
        local opt_name=$(basename "$override_file")
        local opt_file="$retroarch_emulator_config_dir/$opt_name"
        
        grep -E "^$core_name" /opt/retropie/configs/all/retroarch-core-options.cfg > "$opt_file"
        crudini --merge "$opt_file" < "$override_file"
      done
    done < <(system_setting '.emulators | to_entries[] | select(.value.core_name) | [.value.library_name, .value.core_name] | @tsv')
  fi
}

# Games-specific controller remappings
install_game_remappings() {
  # TODO
  # /opt/retropie/configs/arcade/FinalBurn\ Neo/arkanoid.rmp
}

install() {
  install_config
  install_global_core_options
  install_game_core_options
  install_game_remappings
}

uninstall() {
  restore "$retropie_system_config_dir/retroarch.cfg"
}

"$1" "${@:3}"
