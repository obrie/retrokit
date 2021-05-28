#!/bin/bash

set -ex

system='c64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  download 'https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4/export?gid=82569470&format=tsv' "$system_tmp_dir/c64_dreams.tsv"

  # Map normalized name to rom name
  declare -A installed_roms
  while read -r rom_name; do
    local normalized_name=$(normalize_rom_name "$rom_name")
    installed_roms["$normalized_name"]="$rom_name"
  done < <(romkit_cache_list | jq -r '.name')

  # Set joyport based on the above
  while IFS='^' read -r color unknown title type multidisk joyport other; do
    local normalized_name=$(normalize_rom_name "$title")
    if [ -z "$normalized_name" ]; then
      continue
    fi
    
    local rom_name=${installed_roms["$normalized_name"]}

    # Make sure the row is valid and the ROM was installed
    if [ -n "$rom_name" ]; then
      # Possible values are 1, 2, n/a, 1-2, and possible others so we do some
      # fuzzy matching to find the appropriate vlaue
      local joyport_selection
      if [[ "$joyport" == *1* ]]; then
        joyport_selection=1
      elif [[ "$joyport" == *2* ]]; then
        joyport_selection=2
      fi

      if [ -n "$joyport_selection" ]; then
        # Ensure file exists
        local opt_file="$retroarch_config_dir/config/VICE x64/$rom_name.opt"
        mkdir -p "$(dirname "$opt_file")"
        touch "$opt_file"

        # Overwrite joyport selection
        crudini --set "$opt_file" '' 'vice_joyport' "\"$joyport_selection\""
      fi
    fi
  done < <(cat "$system_tmp_dir/c64_dreams.tsv" | tr "$tab" "^")
}

uninstall() {
  # Remove joyport selections
  while read opt_file; do
    crudini --del "$opt_file" '' 'vice_joyport'
    if [ -s "$opt_file" ]; then
      rm "$opt_file"
    fi
  done < <(find "$retroarch_config_dir/config/VICE x64" -name '*.opt')
}

"${@}"
