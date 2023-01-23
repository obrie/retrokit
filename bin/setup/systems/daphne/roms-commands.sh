#!/bin/bash

system='daphne'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/daphne/roms-commands'
setup_module_desc='Daphne game commands to run on startup'

readarray -t rom_dirs < <(system_setting 'select(.roms) | .roms.dirs[] | .path')

configure() {
  local target_overlay_dir=$(system_setting '.overlays .target')

  while IFS=$'\t' read -r rom_name controls; do
    local commands=()

    # Common
    commands+=($(__get_commands '{system_config_dir}/daphne.commands'))

    # Lightgun
    local lightgun_commands
    if [[ "$controls" == *lightgun* ]]; then
      commands+=($(__get_commands '{system_config_dir}/daphne-lightgun.commands'))
    fi

    # Game-specific commands
    local commands+=($(__get_commands "{system_config_dir}/commands/$rom_name.commands"))

    # Bezel
    local bezel_name
    if [ -f "$target_overlay_dir/$rom_name.png" ]; then
      bezel_name=$rom_name
    else
      bezel_name=$system
    fi
    if [ -f "$target_overlay_dir/$bezel_name.png" ]; then
      commands+=(-bezel $bezel_name.png)
    fi

    # Combine commands
    if [ "${#commands}" -gt 0 ]; then
      for rom_dir in "${rom_dirs[@]}"; do
        if [ -e "$rom_dir/$rom_name.daphne" ]; then
          local target_path="$rom_dir/$rom_name.daphne/$rom_name.commands"
          echo "Merging commands to $target_path"
          echo "${commands[@]}" > "$target_path"
        fi
      done
    fi
  done < <(romkit_cache_list | jq -r '[.name, (.controls | join(","))] | @tsv')
}

__get_commands() {
  local path_template=$1

  while read path; do
    local commands=$(head -n 1 "$path")
    if [ -n "$commands" ]; then
      echo "$commands"
    fi
  done < <(each_path "$path_template")
}

restore() {
  for rom_dir in "${rom_dirs[@]}"; do
    find "$rom_dir" -maxdepth 1 -mindepth 1 -name '*.commands' -exec rm -f '{}' +
  done
}

setup "${@}"
