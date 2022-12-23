#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-inputs'
setup_module_desc='Configure game-specific automatic port selection using autoport'

configure() {
  __load_override_files

  mkdir -p "$retropie_system_config_dir/autoport"

  # Track which playlists we've installed so we don't do it twice
  declare -A installed_playlists
  declare -A installed_files

  while IFS=» read -r rom_name title parent_name parent_title playlist_name tags; do
    local group_title=${parent_title:-$title}
    local target_path="$retropie_system_config_dir/autoport/${playlist_name:-$rom_name}.cfg"

    if [ "${installed_files["$target_path"]}" ]; then
      # We've already processed this file (it's a playlist) -- don't process it again
      continue
    fi

    # Remove existing file
    rm -fv "$target_path"

    # Create a default file based on the input type used by the game
    # (e.g. lightgun vs. trackball)
    if [[ "$tags" == *Lightgun* ]]; then
      echo -e '[autoport]\nprofile = "lightgun"' > "$target_path"
      echo "Setting profile to \"lightgun\" in $target_path"
    elif [[ "$tags" == *Trackball* ]]; then
      echo -e '[autoport]\nprofile = "trackball"' > "$target_path"
      echo "Setting profile to \"trackball\" in $target_path"
    fi

    # Find an override file for either the rom or its parent
    local override_file=""
    local filename
    for filename in "$rom_name" "$title" "$parent_name" "$parent_title"; do
      if [ -z "$filename" ]; then
        continue
      fi

      override_file=${override_files["$filename"]}
      if [ -n "$override_file" ]; then
        ini_merge "$override_file" "$target_path" backup=false
        break
      fi
    done

    # Track the newly created configuration
    if [ -f "$target_path" ]; then
      installed_files["$target_path"]=1
    fi
  done < <(romkit_cache_list | jq -r '[.name, .title, .parent.name, .parent.title, .playlist.name, .tags | join(",")] | join("»")')

  # Remove unused files
  while read -r path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$retropie_system_config_dir/autoport" -maxdepth 1 -name '*.cfg')
}

# Load autoport rom-specific configuration overrides
__load_override_files() {
  declare -Ag override_files

  while read override_file; do
    local override_name=$(basename "$override_file" '.cfg')
    override_files["$override_name"]=$override_file
  done < <(each_path '{system_config_dir}/autoport' find '{}' -name '*.cfg')
}

restore() {
  rm -fv "$retropie_system_config_dir/autoport/"*.cfg
}

setup "${@}"
