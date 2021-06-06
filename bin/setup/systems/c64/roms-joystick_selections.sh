#!/bin/bash

system='c64'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  download 'https://docs.google.com/spreadsheets/d/1r6kjP_qqLgBeUzXdDtIDXv1TvoysG_7u2Tj7auJsZw4/export?gid=82569470&format=tsv' "$system_tmp_dir/c64_dreams.tsv"

  # Figure out where the core options live
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null | tr -d '"' || true)
  if [ -z "$core_options_path" ]; then
    core_options_path='/opt/retropie/configs/all/retroarch-core-options.cfg'
  fi

  # Map normalized name to rom name
  declare -A installed_roms
  while read -r rom_name; do
    local normalized_name=$(normalize_rom_name "$rom_name")
    installed_roms["$normalized_name"]="$rom_name"
  done < <(romkit_cache_list | jq -r '.name')

  # Set joyport based on the above
  echo 'Selecting joyport for installed ROMs...'
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
        local opt_file="$retroarch_config_dir/config/VICE x64/$rom_name.opt"

        if [ ! -f "$opt_file" ]; then
          # Copy over existing core overrides so we don't just get the
          # core defaults
          mkdir -pv "$(dirname "$opt_file")"
          touch "$opt_file"
          grep -E '^vice' "$core_options_path" > "$opt_file" || true
        fi

        # Overwrite joyport selection
        echo "Setting vice_joyport to $joyport_selection for $opt_file"
        crudini --set "$opt_file" '' 'vice_joyport' "\"$joyport_selection\""
      fi
    fi
  done < <(cat "$system_tmp_dir/c64_dreams.tsv" | tr "$tab" "^")
}

uninstall() {
  [ ! -d "$retroarch_config_dir/config/VICE x64" ] && return

  # Remove joyport selections
  while read opt_file; do
    crudini --del "$opt_file" '' 'vice_joyport'
    if [ ! -s "$opt_file" ]; then
      rm -v "$opt_file"
    fi
  done < <(find "$retroarch_config_dir/config/VICE x64" -name '*.opt')
}

"${@}"
