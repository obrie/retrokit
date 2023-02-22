#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-cheats'
setup_module_desc='Link roms to game cheat files for libretro'

cheat_database_dir=${retroarch_path_defaults['cheat_database_path']}
system_cheat_database_dir=$(get_retroarch_path 'cheat_database_path')

# If matched, we must find the corresonding country in the ROM name
countries_regex='asia|australia|brazil|china|europe|france|germany|italy|japan|korea|russia|spain|sweden|usa'

# If matched, we must find the corresponding version in the ROM name
versions_regex='proto|rev|beta|demo|unl'

# Prioritized list of which cheat system we prefer (lower index == high priority)
cheat_systems=("action replay" "game genie" gameshark xploder)

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
  local cheats_list_file=$(mktemp -p "$tmp_ephemeral_dir")
  __load_cheat_mappings | sort | uniq > "$cheats_list_file"

  # Link the named Retroarch cheats to the emulator in the system cheats namespace
  declare -A installed_files
  declare -A installed_playlists
  while IFS=$'\t' read -r rom_name emulator playlist_name; do
    emulator=${emulator:-default}
    local library_name=${emulators["$emulator/library_name"]}
    if [ -z "$library_name" ]; then
      # Not a libretro emulator
      continue
    fi

    # Ensure the target exists
    local target_cheats_dir="$system_cheat_database_dir/$library_name"
    mkdir -pv "$target_cheats_dir"

    # We can't just symlink to the source directory because the cheat filenames
    # don't always match the ROM names.  As a result, we need to try to do some
    # smart matching to find the corresponding cheat file.
    local source_cheat_file=$(__find_matching_cheat "$rom_name" "$cheats_list_file")

    if [ -n "$source_cheat_file" ]; then
      if [ -z "$playlist_name" ]; then
        # Link the cheat for single-disc games
        ln_if_different "$source_cheat_file" "$target_cheats_dir/$rom_name.cht"
        installed_files["$target_cheats_dir/$rom_name.cht"]=1
      elif [ ! "${installed_playlists["$playlist_name"]}" ]; then
        # Link the cheat for the playlist
        ln_if_different "$source_cheat_file" "$target_cheats_dir/$playlist_name.cht"
        installed_playlists["$playlist_name"]=1
        installed_files["$target_cheats_dir/$playlist_name.cht"]=1
      fi
    fi
  done < <(romkit_cache_list | jq -r '[.name, .emulator, .playlist.name] | @tsv')

  # Remove old, unmapped cheats
  while read -r library_name; do
    [ ! -d "$system_cheat_database_dir/$library_name" ] && continue

    while read -r path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$system_cheat_database_dir/$library_name" -name '*.cht')
  done < <(get_core_library_names)
}

# Define mappings to make lookups easier and more reliable
__load_cheat_mappings() {
  declare -Ag cheat_mappings
  while read -r cheats_name; do
    # Location of the cheats on the filesystem
    local source_cheats_dir="$cheat_database_dir/$cheats_name"

    while read -r cheat_filename; do
      # Build a unique key to represent the rom name that we can
      # match with our own installed roms
      local cheat_name=${cheat_filename%.*}
      local key=$(normalize_rom_name "$cheat_name")
      echo "$key"$'\t'"$cheat_name"$'\t'"$source_cheats_dir/$cheat_filename"

      # In some cases, multiple ROMs are combined into a single cheat file,
      # separated by " - ".  We need to map each of those individually as
      # well.
      if [[ "$cheat_name" == *-* ]]; then
        while read -r sub_cheat_name; do
          key=$(normalize_rom_name "$sub_cheat_name")
          echo "$key"$'\t'"$cheat_name"$'\t'"$source_cheats_dir/$cheat_filename"
        done < <(printf '%s\n' "${cheat_name// - /$'\n'}")
      fi
    done < <(find "$source_cheats_dir" -name '*.cht' -printf '%f\n')
  done < <(system_setting '.cheats.names[]')
}

# Sort by:
# * Number of version flags that match
# * Number of country flags that match
# * Total number of flags that match
# * Cheat system preference
# * Cheat name length
__find_matching_cheat() {
  local rom_name=$1
  local cheats_list_file=$2
  local normalized_rom_name=$(normalize_rom_name "$rom_name")

  # Look up this ROM's associated flags as cheats can be region-specific
  local rom_flags=$(echo "$rom_name" | grep -oE "\(.+$" | grep -oE "[^\(\), ]+[^\(\),]+" | tr '[:upper:]' '[:lower:]')

  # Track the cheats that might match our ROM
  local cheat_matches=()

  while IFS=$'\t' read cheat_name cheat_filename; do
    # If cheat name has flags in it, then we try to prioritize based on
    # the flags in the rom provided
    local cheat_flags=$(echo "$cheat_name" | grep -oE "\(.+$" | grep -oE "[^\(\), ]+[^\(\),]+" | tr '[:upper:]' '[:lower:]')

    # Prioritization stats
    local country_matches_count=0
    local version_matches_count=0
    local total_matches_count=0
    local cheat_system_index=0
    local cheat_name_length=${#cheat_name}

    # Find matching countries
    if echo "$cheat_flags" | grep -qE '^('"$countries_regex"')$'; then
      country_matches_count=$(comm -12 <(echo "$cheat_flags" | grep -E '^('"$countries_regex"')$' | sort | uniq) <(echo "$rom_flags" | grep -E '^('"$countries_regex"')$' | sort | uniq) | wc -l)
      if [ "$country_matches_count" == '0' ]; then
        continue
      fi
    fi

    # Find matching versions
    if echo "$cheat_flags" | grep -qE '^('"$versions_regex"')'; then
      version_matches_count=$(comm -12 <(echo "$cheat_flags" | grep -E '^('"$versions_regex"')' | sort | uniq) <(echo "$rom_flags" | grep -E '^('"$versions_regex"')' | sort | uniq) | wc -l)
      if [ "$version_matches_count" == '0' ]; then
        continue
      fi
    fi

    # Total matching flags
    total_matches_count=$(comm -12 <(echo "$cheat_flags" | sort | uniq) <(echo "$rom_flags" | sort | uniq) | wc -l)

    # Find matching cheat system
    local i
    for i in "${!cheat_systems[@]}"; do
       if [[ "$cheat_flags" == *"${cheat_systems[$i]}"* ]]; then
          cheat_system_index=$((i+1))
          break
       fi
    done

    cheat_matches+=("$version_matches_count"$'\t'"$country_matches_count"$'\t'"$total_matches_count"$'\t'"$cheat_system_index"$'\t'"$cheat_name_length"$'\t'"$cheat_filename")
  done < <(grep -E "^$normalized_rom_name"$'\t' "$cheats_list_file" | cut -d$'\t' -f 2,3)

  printf "%s\n" "${cheat_matches[@]}" | sort -t$'\t' -k1,1n -k2,2n -k3,3n -k4,4rn -k5,5rn -k6,6r | tail -n 1 | cut -d$'\t' -f 6
}

restore() {
  # Remove cheats for each libretro core
  while read -r library_name; do
    rm -rfv "$system_cheat_database_dir/$library_name"
  done < <(get_core_library_names)
}

setup "${@}"
