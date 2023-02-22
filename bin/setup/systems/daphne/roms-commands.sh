#!/bin/bash

system='daphne'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/daphne/roms-commands'
setup_module_desc='Daphne game commands to run on startup'

readarray -t rom_dirs < <(system_setting 'select(.roms) | .roms.dirs[] | .path')

configure() {
  load_emulator_data

  local target_overlay_dir=$(system_setting '.overlays .target')

  while IFS=» read -r rom_name title group_name emulator controls; do
    emulator=${emulators["${emulator:-default}/emulator"]}

    # Find the target path.  We just need to find the first match since the
    # directory is just symlinked.
    local target_file
    for rom_dir in "${rom_dirs[@]}"; do
      if [ -e "$rom_dir/$rom_name.daphne" ]; then
        target_file="$rom_dir/$rom_name.daphne/$rom_name.commands"
        break
      fi
    done

    # Set up the path that we're writing to
    if [ -z "$target_file" ]; then
      continue
    fi
    rm -fv "$target_file"

    local source_files=("{system_config_dir}/$emulator.commands")

    # Lightgun
    if [[ "$controls" == *lightgun* ]]; then
      source_files+=("{system_config_dir}/$emulator-lightgun.commands")
    fi

    # Game-specific commands
    source_files+=("{system_config_dir}/commands/$rom_name.commands")

    # Merge command sources
    for source_file_template in "${source_files[@]}"; do
      if any_path_exists "$source_file_template"; then
        echo "Merging commands $source_file_template to $target_file"

        while read source_file; do
          local source_commands=$(head -n 1 "$source_file")
          if [ -n "$source_commands" ]; then
            echo -n "$source_commands " >> "$target_file"
          fi
        done < <(each_path "$source_file_template")
      fi
    done

    # Bezel
    local supports_overlays=${emulators["$emulator/supports_overlays"]}
    if [ "$supports_overlays" == 'true' ]; then
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
        echo -n "-bezel $bezel_name.png" >> "$target_file"
      fi
    fi
  done < <(romkit_cache_list | jq -r '[.name, .title, .group .name, .emulator, (.controls | join(","))] | join("»")')
}

restore() {
  for rom_dir in "${rom_dirs[@]}"; do
    find "$rom_dir" -maxdepth 1 -mindepth 1 -name '*.commands' -exec rm -f '{}' +
  done
}

setup "${@}"
