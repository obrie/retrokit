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

install_roms() {
  romkit_cli install --log-level DEBUG
}

install_playlists() {
  while read -r rom_path; do
    local rom_filename=$(basename "$rom_path")

    # Generate the playlist path
    local base_path="${rom_path// (Disc [0-9]*)/}"
    local base_filename=$(basename "$base_path")
    local playlist_path="$(dirname "$base_path")/${base_filename%%.*}.m3u"

    # Reset if we're on the first disc
    if [[ "$rom_filename"  == *'(Disc 1)'* ]]; then
      truncate -s0 "$playlist_path"
    fi

    # Add to the playlist
    echo "$rom_filename" >> "$playlist_path"
  done < <(find "$HOME/RetroPie/roms/$system" . -not -path '*/\.*' -type l -name "*(Disc *" | sort)
}

set_default_emulators() {
  # Define a mapping of rom package to rom name
  declare -A emulator_names
  while IFS="$tab" read -r emulator name; do
    emulator_names["$emulator"]="$name"
  done < <(system_setting '.emulators | to_entries[] | [.key, .value.name // .key] | @tsv')

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
        local emulator_name=${emulator_names["$emulator"]:-$emulator}
        echo "$(clean_emulator_config_key "${system}_${rom_name}") = \"$emulator_name\""
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

list() {
  romkit_cli list
}

vacuum() {
  romkit_cli vacuum
}

install() {
  install_roms
  install_playlists
  set_default_emulators
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
