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

  backup '/opt/retropie/configs/all/emulators.cfg'
  log "--- Setting default emulators ---"

  # Merge emulator configurations
  # 
  # This is done in one batch because it's a bit slow otherwise
  crudini --merge '/opt/retropie/configs/all/emulators.cfg' < <(
    while IFS="$tab" read -r rom_name emulator; do
      echo "$(clean_emulator_config_key "${system}_${rom_name}") = \"$emulator\""
    done < <(romkit_cli list --log-level ERROR | jq -r '[.name, .emulator] | @tsv')
  )
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
