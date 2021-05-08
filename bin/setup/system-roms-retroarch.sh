#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

find_overrides() {
  local extension=$1

  # Map emulator to library name
  local default_emulator=""
  declare -A emulators
  while IFS="$tab" read emulator core_name library_name is_default; do
    emulators["$emulator/core_name"]=$core_name
    emulators["$emulator/library_name"]=$library_name

    if [ "$is_default" == "true" ]; then
      default_emulator=$emulator
    fi
  done < <(system_setting '.emulators | to_entries[] | select(.value.core_name) | [.key, .value.core_name, .value.library_name, .value.default // false] | @tsv')

  if [ -d "$system_config_dir/retroarch" ]; then
    while IFS="^" read rom_name parent_name emulator; do
      # Find a file for either the rom or its parent
      local override_file=""
      if [ -f "$system_config_dir/retroarch/$rom_name.$extension" ]; then
        override_file="$system_config_dir/retroarch/$rom_name.$extension"
      elif [ -f "$system_config_dir/retroarch/$parent_name.$extension" ]; then
        override_file="$system_config_dir/retroarch/$parent_name.$extension"
      fi

      if [ -n "$override_file" ]; then
        # Use the default emulator if one isn't specified
        if [ -z "$emulator" ]; then
          emulator=$default_emulator
        fi

        # Look up emulator attributes as those are the important ones
        # for configuration purposes
        local core_name=${emulators["$emulator/core_name"]}
        local library_name=${emulators["$emulator/library_name"]}

        # Make sure this is a libretro core
        if [ -n "$core_name" ] && [ -n "$library_name" ]; then
          echo "$rom_name$tab$override_file$tab$core_name$tab$library_name"
        fi
      fi
    done < <(romkit_cache_list | jq -r '[.name, .parent, .emulator] | @tsv' | tr "$tab" "^")
  fi
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
install_retroarch_core_options() {
  while IFS="$tab" read rom_name override_file core_name library_name; do
    # Retroarch emulator-specific config
    local retroarch_emulator_config_dir="$retroarch_config_dir/config/$library_name"
    mkdir -p "$retroarch_emulator_config_dir"

    # Back up the existing file
    local target_path="$retroarch_emulator_config_dir/$rom_name.opt"
    backup_and_restore "$target_path"

    # Copy over existing core overrides so we don't just get the
    # core defaults
    touch "$target_path"
    grep -E "^$core_name" /opt/retropie/configs/all/retroarch-core-options.cfg > "$target_path" || true

    # Merge in game-specific overrides
    crudini --merge "$target_path" < "$override_file"
  done < <(find_overrides 'opt')
}

# Games-specific controller mapping overrides
install_retroarch_remappings() {
  local remapping_dir=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'input_remapping_directory' 2>/dev/null || true)

  if [ -n "$remapping_dir" ]; then
    while IFS="$tab" read rom_name override_file core_name library_name; do
      # Emulator-specific remapping directory
      local emulator_remapping_dir="$remapping_dir$library_name"
      mkdir -p "$emulator_remapping_dir"

      ini_merge "$override_file" "$emulator_remapping_dir/$rom_name.rmp"
    done < <(find_overrides 'rmp')
  fi
}

# Game-specific retroarch configuration overrides
install_retroarch_configs() {
  while IFS="$tab" read rom_name override_file core_name library_name; do
    ini_merge "$override_file" "$HOME/RetroPie/roms/$system/$rom_name.cfg"
  done < <(find_overrides 'cfg')
}

install() {
  install_retroarch_configs
  install_retroarch_remappings
  install_retroarch_core_options
}

uninstall() {
  echo 'No uninstall for rom retroarch configurations'
}

"$1" "${@:3}"
