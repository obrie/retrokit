#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-cheats'
setup_module_desc='Link roms to game cheat files for libretro'

cheat_database_path=${retroarch_path_defaults['cheat_database_path']}
system_cheat_database_path=$(get_retroarch_path 'cheat_database_path')

configure() {
  # Name of the cheats for this system
  if [ -z "$(system_setting '.cheats.names')" ]; then
    echo 'No cheats configured'
    return
  fi

  # Load emulator data for finding the library_name
  load_emulator_data

  # Define mappings to make lookups easier and more reliable
  echo 'Loading list of available cheats...'
  __load_cheat_mappings

  # Link the named Retroarch cheats to the emulator in the system cheats namespace
  declare -A installed_files
  declare -A installed_playlists
  while IFS=$'\t' read -r rom_name emulator; do
    emulator=${emulator:-default}
    local library_name=${emulators["$emulator/library_name"]}
    if [ -z "$library_name" ]; then
      # Not a libretro emulator
      continue
    fi

    # Ensure the target exists
    local target_cheats_dir="$system_cheat_database_path/$library_name"
    mkdir -pv "$target_cheats_dir"

    # We can't just symlink to the source directory because the cheat filenames
    # don't always match the ROM names.  As a result, we need to try to do some
    # smart matching to find the corresponding cheat file.
    local normalized_rom_name=$(normalize_rom_name "$rom_name")
    local cheat_name=${cheat_mappings["$normalized_rom_name"]}
    local source_cheats_dir=${cheat_mappings["$normalized_rom_name/source"]}

    if [ -n "$cheat_name" ]; then
      # Link the cheat for either a single-disc game or, if configured, individual discs
      if has_disc_config "$rom_name"; then
        ln -fsv "$source_cheats_dir/$cheat_name.cht" "$target_cheats_dir/$rom_name.cht"
        installed_files["$target_cheats_dir/$rom_name.cht"]=1
      fi

      # Link the cheat for the playlist (if applicable)
      local playlist_name=$(get_playlist_name "$rom_name")
      if has_playlist_config "$rom_name" && [ ! "${installed_playlists["$playlist_name"]}" ]; then
        ln -fsv "$source_cheats_dir/$cheat_name.cht" "$target_cheats_dir/$playlist_name.cht"
        installed_playlists["$playlist_name"]=1
        installed_files["$target_cheats_dir/$playlist_name.cht"]=1
      fi
    fi
  done < <(romkit_cache_list | jq -r '[.name, .emulator] | @tsv')

  # Remove old, unmapped cheats
  while read -r library_name; do
    [ ! -d "$system_cheat_database_path/$library_name" ] && continue

    while read -r path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$system_cheat_database_path/$library_name" -name '*.cht')
  done < <(get_core_library_names)
}

# Define mappings to make lookups easier and more reliable
__load_cheat_mappings() {
  declare -Ag cheat_mappings
  while read -r cheats_name; do
    # Location of the cheats on the filesystem
    local source_cheats_dir="$cheat_database_path/$cheats_name"

    while read -r cheat_filename; do
      # Build a unique key to represent the rom name that we can
      # match with our own installed roms
      local cheat_name=${cheat_filename%.*}
      local key=$(normalize_rom_name "$cheat_name")

      # Only re-map if we need to.  This prioritizes exact matches.
      local existing_mapping=${cheat_mappings["$key"]}
      if [ -z "$existing_mapping" ]; then
        cheat_mappings["$key"]="$cheat_name"
        cheat_mappings["$key/source"]="$source_cheats_dir"

        # In some cases, multiple ROMs are combined into a single cheat file,
        # separated by " - ".  We need to map each of those individually as
        # well.
        while read -r sub_cheat_name; do
          key=$(normalize_rom_name "$sub_cheat_name")
          existing_mapping=${cheat_mappings["$key"]}

          if [ -z "$existing_mapping" ]; then
            cheat_mappings["$key"]="$cheat_name"
            cheat_mappings["$key/source"]="$source_cheats_dir"
          fi
        done < <(printf '%s\n' "${cheat_name// - /$'\n'}")
      fi
    done < <(ls "$source_cheats_dir" | awk '{ print length, $0 }' | sort -n -s | cut -d" " -f2-)
  done < <(system_setting '.cheats.names[]')
}

restore() {
  # Remove cheats for each libretro core
  while read -r library_name; do
    rm -rfv "$system_cheat_database_path/$library_name"
  done < <(get_core_library_names)
}

setup "$1" "${@:3}"
