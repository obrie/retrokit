#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-inputs'
setup_module_desc='Configure game-specific automatic port selection using autoport'

configure() {
  # Load which overrides are available to merge
  declare -A override_names
  while read override_file; do
    local override_name=$(basename "$override_file" '.cfg')
    override_names["$override_name"]=1
  done < <(each_path '{system_config_dir}/autoport' find '{}' -name '*.cfg')

  mkdir -p "$retropie_system_config_dir/autoport"

  # Track which playlists we've installed so we don't do it twice
  declare -A installed_playlists
  declare -A installed_files

  while IFS=» read -r rom_name disc_name playlist_name title parent_name group_name controls; do
    local target_file="$retropie_system_config_dir/autoport/${playlist_name:-$rom_name}.cfg"
    if [ "${installed_files["$target_file"]}" ]; then
      # We've already processed this file (it's a playlist) -- don't process it again
      continue
    fi

    # Remove existing file
    rm -fv "$target_file"

    # Create a default file based on the primary input type used by the game
    local control_type=$(get_primary_control "$controls")
    if [ -n "$control_type" ]; then
      echo -e "[autoport]\nprofile = \"$control_type\"" > "$target_file"
      echo "Setting profile to \"$control_type\" in $target_file"
    fi

    # Merge in overrides (lowest to highest priority)
    local override_name
    declare -A merged_names
    for override_name in "$group_name" "$title" "$disc_name" "$parent_name" "$playlist_name" "$rom_name"; do
      if [ -n "$override_name" ] && [ "${override_names[$override_name]}" ] && [ ! "${merged_names[$override_name]}" ]; then
        ini_merge "{system_config_dir}/autoport/$override_name.cfg" "$target_file" backup=false
        merged_names[$override_name]=1
      fi
    done

    # Track the newly created configuration
    if [ -f "$target_file" ]; then
      installed_files["$target_file"]=1
    fi
  done < <(romkit_cache_list | jq -r '[.name, .disc, .playlist.name, .title, .parent.name, .group.name, (.controls | join(","))] | join("»")')

  # Remove unused files
  while read -r path; do
    [ "${installed_files["$path"]}" ] || rm -v "$path"
  done < <(find "$retropie_system_config_dir/autoport" -maxdepth 1 -name '*.cfg')
}

restore() {
  rm -fv "$retropie_system_config_dir/autoport/"*.cfg
}

setup "${@}"
