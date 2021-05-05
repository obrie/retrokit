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

# Loads the list of roms marked for install.  This can be called multiple
# times, but it will only run once.
cached_list() {
  if [ -z "$rom_install_list" ]; then
    rom_install_list=$(list)
  fi

  echo "$rom_install_list"
}

# Install roms from the remote source
install_roms() {
  romkit_cli install --log-level DEBUG
}

# Install playlists for multi-disc roms
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

find_overrides() {
  local extension=$1

  if [ -d "$system_config_dir/retroarch" ]; then
    while read rom_name parent_name; do
      # Find a file for either the rom or its parent
      local override_file
      if [ -f "$system_config_dir/retroarch/$rom_name.$extension" ]; then
        override_file="$system_config_dir/retroarch/$rom_name.$extension"
      elif [ -f "$system_config_dir/retroarch/$parent_name.$extension" ]; then
        override_file="$system_config_dir/retroarch/$parent_name.$extension"
      fi

      if [ -n "$override_file" ]; then
        echo "$override_file"
      fi
    done < <(cached_list | jq -r '[.name, .parent] | @tsv')
  fi
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
install_core_options() {
  local emulators=$(system_setting '.emulators | to_entries[] | select(.value.core_name) | [.value.library_name, .value.core_name] | @tsv')

  while read override_file; do
    while read library_name core_name; do
      # Retroarch emulator-specific config
      local retroarch_emulator_config_dir="$retroarch_config_dir/config/$library_name"
      mkdir -p "$retroarch_emulator_config_dir"

      local override_filename=$(basename "$override_file")
      local target_path="$retroarch_emulator_config_dir/$override_filename"
      
      # Copy over existing core overrides so we don't just get the
      # core defaults
      grep -E "^$core_name" /opt/retropie/configs/all/retroarch-core-options.cfg > "$target_path"

      # Merge in game-specific overrides
      crudini --merge "$target_path" < "$override_file"
    done < <(echo "$emulators")
  done < <(find_overrides 'opt')
}

# Games-specific controller mapping overrides
install_remappings() {
  local remapping_dir=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'input_remapping_directory' 2>/dev/null || true)

  if [ -n "$remapping_dir" ]; then
    local emulators=$(system_setting '.emulators | to_entries[] | select(.value.library_name) | [.value.library_name] | @tsv')
    
    while read override_file; do
      while read library_name; do
        # Emulator-specific remapping directory
        local emulator_remapping_dir="$remapping_dir/$library_name"
        mkdir -p "$emulator_remapping_dir"

        local override_filename=$(basename "$override_file")
        cp "$override_file" "$emulator_remapping_dir/$override_filename"
      done < <(echo "$emulators")
    done < <(find_overrides 'rmp')
  fi
}

# Game-specific retroarch configuration overrides
install_retroarch_configs() {
  while read override_file; do
    cp "$override_file" "$HOME/RetroPie/roms/$system/$(basename "$override_file")"
  done < <(find_overrides 'cfg')
}

# Define emulators for games that don't use the default
set_default_emulators() {
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
    done < <(cached_list | jq -r '[.name, .emulator] | @tsv')
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
  done < <(cached_list | jq -r '[.name, .emulator] | @tsv')
}

list() {
  romkit_cli list --log-level ERROR
}

vacuum() {
  romkit_cli vacuum --log-level ERROR
}

install() {
  install_roms
  install_playlists
  install_retroarch_configs
  install_remappings
  install_core_options
  set_default_emulators
}

uninstall() {
  echo 'No uninstall for roms'
}

"$1" "${@:3}"
