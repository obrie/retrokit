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

    # Define mappings to make lookups easier and more reliable
    declare -A cheat_mappings
    while IFS= read -r cheat_filename; do
      local cheat_name="${cheat_filename%.*}"
      local key="$(clean_rom_name "$cheat_name")"
      local existing_mapping=${cheat_mappings["$key"]}

      # Only re-map if we need to.  This prioritizes exact matches.
      if [ -z "$existing_mapping" ]; then
        cheat_mappings["$key"]="$cheat_name"

        # In some cases, multiple ROMs are combined into a single cheat file
        while read -r sub_cheat_name; do
          key="$(clean_rom_name "$sub_cheat_name")"
          existing_mapping=${cheat_mappings["$key"]}

          if [ -z "$existing_mapping" ]; then
            cheat_mappings["$key"]="$cheat_name"
          fi
        done < <(printf '%s\n' "${cheat_name// - /$'\n'}")
      fi
    done < <(ls "$source_cheats_dir" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2-)

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
        local rom_name="${rom_filename%.*}"
        local cheat_name=${cheat_mappings["$(clean_rom_name "$rom_name")"]}

        if [ -n "$cheat_name" ]; then
          ln -fs "$source_cheats_dir/$cheat_name.cht" "$target_cheats_dir/$rom_name.cht"
        fi
      done < <(find "$HOME/RetroPie/roms/$system" -type l -printf '"%p"\n' | xargs -I{} basename "{}" | sort | uniq)
    done < <(system_setting '.emulators | try to_entries[] | select(.value.library_name) | [.key, .value.library_name] | @tsv')
  fi
}

uninstall() {
  echo 'No uninstall for rom cheats'
}

"$1" "${@:3}"
