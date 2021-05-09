#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# This install individual overlays from The Bezel Project.  We use this instead of
# The Bezel Project's installer in order to reduce the amount of disk space required.
install() {
  # Base URL for downloading overlays
  local bezelproject_name=$(system_setting '.themes.bezel')
  local bezelproject_base_url="https://github.com/thebezelproject/bezelproject-$bezelproject_name/raw/master/retroarch"
  local bezelproject_overlay_path="overlay/GameBezels/$bezelproject_name"
  if [ "$system" == 'arcade' ]; then
    # Arcade override for unknown reasons
    bezelproject_overlay_path='overlay/ArcadeBezels'
  fi

  # The directory to which we'll install the configurations and images
  local overlays_dir="$retroarch_config_dir/overlay/GameBezels/$bezelproject_name"

  # Map emulator to library name
  local default_emulator=""
  declare -A emulators
  while IFS="$tab" read emulator library_name is_default; do
    emulators["$emulator/library_name"]=$library_name

    if [ "$is_default" == "true" ]; then
      default_emulator=$emulator
    fi
  done < <(system_setting '.emulators | to_entries[] | select(.value.library_name) | [.key, .value.library_name, .value.default // false] | @tsv')

  if [ -n "$bezelproject_name" ]; then
    # Copy over the default overlay
    local input_overlay=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'input_overlay')
    local input_overlay_name=$(basename "$input_overlay" .cfg)
    download "$bezelproject_base_url/overlay/$input_overlay_name.cfg" "$retroarch_config_dir/overlay/$input_overlay_name.cfg"
    download "$bezelproject_base_url/overlay/$input_overlay_name.png" "$retroarch_config_dir/overlay/$input_overlay_name.png"

    # Download overlays for the associated emulator
    while IFS="$tab" read rom_name emulator; do
      # Use the default emulator if one isn't specified
      if [ -z "$emulator" ]; then
        emulator=$default_emulator
      fi
      local library_name=${emulators["$emulator/library_name"]}

      # Make sure this is a libretro core
      if [ -n "$library_name" ]; then
        # Install overlay (if available)
        if download "$bezelproject_base_url/$bezelproject_overlay_path/$rom_name.cfg" "$overlays_dir/$rom_name.cfg"; then
          download "$bezelproject_base_url/$bezelproject_overlay_path/$rom_name.png" "$overlays_dir/$rom_name.png"

          # Link emulator configuration to overlay
          echo "input_overlay = \"$overlays_dir/$rom_name.cfg\"" > "$retroarch_config_dir/config/$library_name/$rom_name.cfg"
        else
          echo "[$rom_name] No overlay available"
        fi
      fi
    done < <(romkit_cache_list | jq -r '[.name, .emulator] | @tsv')
  fi
}

uninstall() {
  echo 'No uninstall for overlays'
}

"$1" "${@:3}"
