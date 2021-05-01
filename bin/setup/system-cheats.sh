#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  # Name of the cheats for this system
  local cheats_name=$(system_setting '.cheats')

  if [ -n "$cheats_name" ]; then
    # Location of the cheats on the filesystem
    local cheat_database_path="$retroarch_config_dir/cheats"
    local source_cheats_dir="$cheat_database_path/$cheats_name"

    # Get cheat database path for this system
    local system_cheat_database_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'cheat_database_path' 2>/dev/null || true)
    system_cheat_database_path="${system_cheat_database_path//\"}"
    if [ -z "$system_cheat_database_path" ]; then
      system_cheat_database_path="$cheat_database_path"
    fi
    mkdir -p "$system_cheat_database_path"

    # Link the named Retroarch cheats to the emulator in the system cheats namespace
    while IFS="$tab" read emulator library_name; do
      local target_cheats_dir="$system_cheat_database_path/$library_name"

      # Reset the directory
      rm -rf "$target_cheats_dir"
      mkdir -p "$target_cheats_dir"

      # We can't just symlink to the source directory because the cheat filenames
      # don't always match the ROM names.  As a result, we need to try to do some
      # smart matching to find the corresponding cheat file.
      while IFS= read -r rom_filename; do
        # Find a matching cheat by:
        # * Exact name match
        # * Inclusive name match
        # * Exact title match
        # * Inclusive title match
        rom_name="${rom_filename%.*}"
        rom_title="${rom_filename%% \(*}"
        rom_cheat_path=$(find "$source_cheats_dir" -name "$rom_name.cht" -o -name "$rom_name*.cht" -o -name "$rom_title.cht" -o -name "$rom_title (*.cht" | head -n 1)

        if [ -n "$rom_cheat_path" ]; then
          ln -fs "$rom_cheat_path" "$target_cheats_dir/$rom_name.cht"
        fi
      done < <(find "$HOME/RetroPie/roms/$system" -type l -printf '"%p"\n' | xargs -I{} basename "{}" | sort | uniq)
    done < <(system_setting '.emulators | try to_entries[] | select(.value.library_name) | [.key, .value.library_name] | @tsv')
  fi
}

uninstall() {
  echo 'No uninstall for cheats'
}

"$1" "${@:3}"
