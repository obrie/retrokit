#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-emulators'
setup_module_desc='Manages emulator selections for individual ROMs'

emulators_config_file="$retropie_configs_dir/all/emulators.cfg"

# Define emulators for games that don't use the default
configure() {
  backup_file "$emulators_config_file"

  # Load emulator data
  load_emulator_data

  # Identify new emulator selections
  echo 'Identifying emulator selections...'
  local selections_cfg=''
  while IFS=$field_delim read -r rom_name playlist_name source_emulator; do
    local target_emulator=${emulators["$source_emulator/emulator"]:-$source_emulator}
    local config_key=$(__clean_emulator_config_key "${system}_${playlist_name:-$rom_name}")

    # Remove it from existing selections so we know what we should delete
    # at the end of this
    selections_cfg+="$config_key = \"$target_emulator\"\n"
  done < <(romkit_cache_list | jq -r 'select(.emulator) | [.name, .playlist .name, .emulator] | join("'$field_delim'")')

  echo 'Replacing emulator selections...'
  touch "$emulators_config_file"
  sed -i "/^${system}_/d" "$emulators_config_file"
  crudini --merge "$emulators_config_file" < <(echo -e "$selections_cfg")
  sort -o "$emulators_config_file" "$emulators_config_file"
}

# Clean the configuration key used for defining ROM-specific emulator options
# 
# Implementation pulled from retropie
__clean_emulator_config_key() {
  local name="$1"
  name="${name//\//_}"
  name="${name//[^a-zA-Z0-9_\-]/}"
  echo "$name"
}

restore() {
  if [ ! -f "$emulators_config_file" ]; then
    return
  fi

  echo 'Removing emulator selections...'
  sed -i "/^${system}_/d" "$emulators_config_file"

  if [ ! -s "$emulators_config_file" ] && [ -f "$emulators_config_file.rk-src.missing" ]; then
    # Restore the file to its original, missing state since the file is now empty
    restore_file "$emulators_config_file" delete_src=true
  fi
}

setup "${@}"
