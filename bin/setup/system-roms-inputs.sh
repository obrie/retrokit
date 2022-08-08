#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-inputs'
setup_module_desc='Configure game-specific automatic port selection using autoport'

configure() {
  __load_override_files
  __load_lightgun_titles
  __load_trackball_titles

  # Track which playlists we've installed so we don't do it twice
  declare -A installed_playlists
  declare -A installed_files

  while IFS=» read -r rom_name title parent_name parent_title playlist_name; do
    local group_title=${parent_title:-$title}
    local target_path="$retropie_system_config_dir/autoport/${playlist_name:-$rom_name}.cfg"

    if [ "${installed_files["$target_path"]}" ]; then
      # We've already processed this file (it's a playlist) -- don't process it again
      continue
    fi

    # Find a file for either the rom or its parent
    local override_file=""
    local filename
    for filename in "$rom_name" "$title" "$parent_name" "$parent_title"; do
      override_file=${override_files["$filename"]}
      if [ -n "$override_file" ]; then
        break
      fi
    done

    # Either use the override file or a default based on the input type used by
    # the game (e.g. lightgun vs. trackball)
    local target_path_created=true
    if [ -n "$override_file" ]; then
      ini_merge "$override_file" "$target_path" backup=false
    elif [ "${lightgun_titles["$group_title"]}" ]; then
      echo 'profile = "lightgun"' > "$target_path"
    elif [ "${trackball_titles["$group_title"]}" ]; then
      echo 'profile = "trackball"' > "$target_path"
    else
      target_path_created=false
    fi

    # Track the newly created configuration
    if [ "$target_path_created" == 'true' ]; then
      installed_files["$target_path"]=1
    fi
  done < <(romkit_cache_list | jq -r '[.name, .title, .parent.name, .parent.title, .playlist.name] | join("»")')

  # Remove unused files
  while read -r path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$retropie_system_config_dir/autoport" -name '*.cfg')
}

# Load autoport rom-specific configuration overrides
__load_override_files() {
  declare -Ag override_files

  while read override_file; do
    local override_name=$(basename "$override_file" '.cfg')
    override_files["$override_name"]=$override_file
  done < <(each_path '{system_config_dir}/autoport' find '{}' -name '*.cfg')
}

# Load titles identified as lightgun games
__load_lightgun_titles() {
  declare -Ag lightgun_titles

  while read -r rom_title; do
    lightgun_titles["$rom_title"]=1
  done < <(each_path '{config_dir}/emulationstation/collections/custom-Lightguns.tsv' cat '{}' | grep -E "^$system"$'\t' | cut -d$'\t' -f 2)
}

# Load titles identified as trackball games
__load_trackball_titles() {
  declare -Ag trackball_titles

  while read -r rom_title; do
    trackball_titles["$rom_title"]=1
  done < <(each_path '{config_dir}/emulationstation/collections/custom-Trackball.tsv' cat '{}' | grep -E "^$system"$'\t' | cut -d$'\t' -f 2)
}

restore() {
  # Remove autoport configs
  rm -rfv "$retropie_system_config_dir/autoport"
}

setup "$1" "${@:3}"
