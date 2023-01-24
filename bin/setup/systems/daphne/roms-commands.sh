#!/bin/bash

system='daphne'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/daphne/roms-commands'
setup_module_desc='Daphne game commands to run on startup'

readarray -t rom_dirs < <(system_setting 'select(.roms) | .roms.dirs[] | .path')

configure() {
  local target_overlay_dir=$(system_setting '.overlays .target')

  while IFS=$'\t' read -r rom_name title group_name controls; do
    # Find the target path.  We just need to find the first match since the
    # directory is just symlinked.
    local target_path
    for rom_dir in "${rom_dirs[@]}"; do
      if [ -e "$rom_dir/$rom_name.daphne" ]; then
        target_path="$rom_dir/$rom_name.daphne/$rom_name.commands"
        break
      fi
    done

    if [ -z "$target_path" ]; then
      continue
    fi
    rm -fv "$target_path"

    local source_paths=('{system_config_dir}/daphne.commands')

    # Lightgun
    if [[ "$controls" == *lightgun* ]]; then
      source_paths+=('{system_config_dir}/daphne-lightgun.commands')
    fi

    # Game-specific commands
    source_paths+=("{system_config_dir}/commands/$rom_name.commands")

    # Merge command sources
    for source_path_template in "${source_paths[@]}"; do
      if any_path_exists "$source_path_template"; then
        echo "Merging commands $source_path_template to $target_path"

        while read source_path; do
          local source_commands=$(head -n 1 "$source_path")
          if [ -n "$source_commands" ]; then
            echo -n "$source_commands " >> "$target_path"
          fi
        done < <(each_path "$source_path_template")
      fi
    done

    # Bezel
    local bezel_name
    if [ -f "$target_overlay_dir/$title.png" ]; then
      bezel_name=$title
    elif [ -f "$target_overlay_dir/$group_name.png" ]; then
      bezel_name=$group_name
    else
      bezel_name=$system
    fi
    if [[ "$controls" == *lightgun* ]]; then
      bezel_name="$bezel_name-lightgun"
    fi
    if [ -f "$target_overlay_dir/$bezel_name.png" ]; then
      echo -n "-bezel $bezel_name.png" >> "$target_path"
    fi
  done < <(romkit_cache_list | jq -r '[.name, .title, .group .name, (.controls | join(","))] | @tsv')
}

restore() {
  for rom_dir in "${rom_dirs[@]}"; do
    find "$rom_dir" -maxdepth 1 -mindepth 1 -name '*.commands' -exec rm -f '{}' +
  done
}

setup "${@}"
