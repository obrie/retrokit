#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Define emulators for games that don't use the default
install() {
  local emulators_config_file='/opt/retropie/configs/all/emulators.cfg'
  backup "$emulators_config_file"

  # Add emulator selections for roms with an explicit one
  # 
  # This is done in one batch because it's a bit slow otherwise
  crudini --merge "$emulators_config_file" < <(
    while IFS="$tab" read -r rom_name emulator; do
      if [ -n "$emulator" ]; then
        echo "$(clean_emulator_config_key "${system}_${rom_name}") = \"$emulator\""
      fi
    done < <(romkit_cache_list | jq -r '[.name, .emulator] | @tsv')
  )

  # Remove emulator selections for roms without one
  while IFS="$tab" read -r rom_name emulator; do
    if [ -z "$emulator" ]; then
      local config_key=$(clean_emulator_config_key "${system}_${rom_name}")

      # Grep for the file before running crudini since crudini is generally much
      # slower and we don't want to invoke it if we don't need to
      if grep "$config_key" "$emulators_config_file"; then
        crudini --del "$emulators_config_file" '' "$config_key"
      fi
    fi
  done < <(romkit_cache_list | jq -r '[.name, .emulator] | @tsv')
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
