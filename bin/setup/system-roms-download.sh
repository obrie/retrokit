#!/bin/bash

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
  local log_level
  if [ "$DEBUG" == 'true' ]; then
    log_level='DEBUG'
  else
    log_level='INFO'
  fi

  echo 'Looking for new ROMs to download...'
  romkit_cli install --log-level "$log_level"
}

# Define emulators for games that don't use the default
install_emulator_selections() {
  local emulators_config_file='/opt/retropie/configs/all/emulators.cfg'
  backup "$emulators_config_file"

  # Load emulator data
  load_emulator_data

  # Look up existing emulator selections
  declare -A existing_selections
  while read config_key; do
    existing_selections["$config_key"]=1
  done < <(crudini --get "$emulators_config_file" '' | grep -E "^${system}_")

  # Identify new emulator selections
  local new_selections=""
  while IFS="$tab" read -r rom_name source_emulator; do
    local target_emulator=${emulators["$source_emulator/emulator"]}
    if [ -n "$target_emulator" ]; then
      local config_key=$(clean_emulator_config_key "${system}_${rom_name}")

      # Remove it from existing selections so we know what we should delete
      # at the end of this
      unset existing_selections["$config_key"]

      new_selections+="$config_key = \"$target_emulator\"\n"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .emulator] | @tsv')

  # Add emulator selections for roms with an explicit one
  echo 'Adding emulator selections...'
  crudini --merge "$emulators_config_file" < <(echo -e "$new_selections")

  # Remove emulator selections for roms without one
  echo 'Removing unused emulator selections...'
  for config_key in "${!existing_selections[@]}"; do
    crudini --del "$emulators_config_file" '' "$config_key"
  done
}

# Download roms from a remote source
install() {
  install_roms
  install_emulator_selections
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
