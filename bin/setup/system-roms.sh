#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Clean the configuration key used for defining ROM-specific emulator options
# 
# Implementation pulled from retropie
clean_emulator_config_key() {
  local name="$1"
  name="${name//\//_}"
  name="${name//[^a-zA-Z0-9_\-]/}"
  echo "$name"
}

install() {
  romkit_cli install --log-level DEBUG

  log "--- Setting default emulators ---"
  local emulators_config_file='/opt/retropie/configs/all/emulators.cfg'
  backup "$emulators_config_file"

  local rom_emulators=$(romkit_cli list --log-level ERROR | jq -r '[.name, .emulator] | @tsv')

  # Add emulator selections for roms with an explicit one
  # 
  # This is done in one batch because it's a bit slow otherwise
  crudini --merge "$emulators_config_file" < <(
    while IFS="$tab" read -r rom_name emulator; do
      if [ -n "$emulator" ]; then
        echo "$(clean_emulator_config_key "${system}_${rom_name}") = \"$emulator\""
      fi
    done < <(echo "$rom_emulators")
  )

  # Remove emulator selections for roms without one
  while IFS="$tab" read -r rom_name emulator; do
    if [ -z "$emulator" ]; then
      local config_key=$(clean_emulator_config_key "${system}_${rom_name}")

      # Grep for the file before running crudini since crudini is generally much
      # slower and we don't want to invoke it if we don't need to
      if grep "$config_key" "$emulators_config_file"; then
        crudini --del "$emulators_config_file" '' $(clean_emulator_config_key "${system}_${rom_name}")
      fi
    fi
  done < <(echo "$rom_emulators")
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
