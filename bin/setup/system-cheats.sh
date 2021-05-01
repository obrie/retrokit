#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# Generates a distinct name for a cheat file so that we can consistently
# look it up based on a ROM name.
# * Lowercase
# * Exclude flags
# * Exclude unimportant characters (dashes, spaces, etc.)
# clean_cheat_name() {
#   local name="$1"
#   name="${name,,}"
#   name="${name%% \(*}"
#   name="${name//[^a-zA-Z0-9]/}"
#   echo "$name"
# }

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

    # Define mappings to make looking easier
    declare -A cheat_mappings
    while IFS= read -r cheat_filename; do
      local cheat_name="${cheat_filename%.*}"
      cheat_mappings["$(clean_cheat_name "$cheat_name")"]="$cheat_name"

      # In some cases, multiple ROMs are combined into a single cheat file
      while read -r sub_cheat_name; do
        cheat_mappings["$(clean_cheat_name "$sub_cheat_name")"]="$cheat_name"
      done < <(printf '%s\n' "${cheat_name// - /$'\n'}")
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
        # Find a matching cheat by:
        # * Exact name match
        # * Inclusive name match
        # * Exact title match
        # * Inclusive title match
        local rom_name="${rom_filename%.*}"
        local cheat_name=${cheat_mappings["$(clean_cheat_name "$rom_name")"]}
        # rom_title="${rom_filename%% \(*}"
        # rom_title_alt_2="${rom_title// - /-}"
        # rom_title_alt_3="${rom_title//-/}"

        # for file_pattern in "$rom_name.cht" "*$rom_name*.cht" "$rom_title.cht" "$rom_title_alt_2.cht" "$rom_title_alt_3.cht" "*$rom_title*.cht" "*$rom_title_alt_2*.cht" "*$rom_title_alt_3*.cht"; do
        #   rom_cheat_path=$(find "$source_cheats_dir" -iname "$file_pattern" | sort | head -n 1)

          if [ -n "$cheat_name" ]; then
            # Found the path -- link and stop looking
            ln -fs "$source_cheats_dir/$cheat_name" "$target_cheats_dir/$rom_name.cht"
            # break
          fi
        # done
      done < <(find "$HOME/RetroPie/roms/$system" -type l -printf '"%p"\n' | xargs -I{} basename "{}" | sort | uniq)
    done < <(system_setting '.emulators | try to_entries[] | select(.value.library_name) | [.key, .value.library_name] | @tsv')
  fi
}

uninstall() {
  echo 'No uninstall for cheats'
}

"$1" "${@:3}"
