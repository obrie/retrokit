#!/bin/bash

system='daphne'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='system/daphne/roms-commands'
setup_module_desc='Daphne game commands to run on startup'

hypseus_launch_file="$retropie_dir/emulators/hypseus/hypseus.sh"
hypseus_commands_dir="$retropie_system_config_dir/commands"

configure() {
  load_emulator_data
  __configure_params
  __configure_commands
}

# Sets up the hypseus launch file to look for commands files in a shared
# configuration directory rather than within the rom's directory
__configure_params() {
  backup_and_restore "$hypseus_launch_file" as_sudo=true

  local insert_line=$(grep -nE '^if' "$hypseus_launch_file" | head -n 1 | cut -d: -f 1)
  local append_to_script="if [[ -f \"$hypseus_commands_dir/\$name.commands\" ]]; then params=\$(<\"$hypseus_commands_dir/\$name.commands\"); fi"
  sudo sed -i "$insert_line i $append_to_script" "$hypseus_launch_file"
}

__configure_commands() {
  local target_overlay_dir=$(system_setting '.overlays .target')

  while IFS=» read -r rom_name title group_name emulator controls; do
    emulator=${emulators["${emulator:-default}/emulator"]}

    # Set up the path that we're writing to
    local target_file="$hypseus_commands_dir/commands/$rom_name.commands"
    mkdir -p "$hypseus_commands_dir/commands"
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
  restore_file "$hypseus_launch_file" as_sudo=true delete_src=true
  rm -rfv "$hypseus_commands_dir"
}

setup "${@}"
