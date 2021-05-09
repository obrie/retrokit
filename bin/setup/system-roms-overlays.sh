#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

# This install individual overlays from The Bezel Project.  We use this instead of
# The Bezel Project's installer in order to reduce the amount of disk space required.
# 
# Yes, this takes longer.  However, we save approx. ~10x in space.  We also don't
# clone so that we don't have to pull down the entire repo any time there's a new
# ROM added.
install() {
  # Base URL for downloading overlays
  local bezelproject_name=$(system_setting '.themes.bezel')
  local bezelproject_base_url="https://github.com/thebezelproject/bezelproject-$bezelproject_name/raw/master/retroarch"
  local bezelprojectsa_base_url="https://github.com/thebezelproject/bezelprojectsa-$bezelproject_name/raw/master/retroarch"
  local bezelproject_overlay_path="overlay/GameBezels/$bezelproject_name"
  if [ "$system" == 'arcade' ]; then
    # Arcade override for unknown reasons
    bezelproject_overlay_path='overlay/ArcadeBezels'
  fi

  # The directory to which we'll install the configurations and images
  local overlays_dir="$retroarch_config_dir/overlay/GameBezels/$bezelproject_name"

  # Map emulator to library name
  local default_emulator=''
  declare -A emulators
  while IFS="$tab" read emulator library_name is_default; do
    emulators["$emulator/library_name"]=$library_name

    if [ "$is_default" == "true" ]; then
      default_emulator=$emulator
    fi
  done < <(system_setting '.emulators | to_entries[] | select(.value.library_name) | [.key, .value.library_name, .value.default // false] | @tsv')

  if [ -n "$bezelproject_name" ]; then
    # Get the list of files available in each repo
    download "https://api.github.com/repos/thebezelproject/bezelproject-$bezelproject_name/git/trees/master?recursive=true" "$system_tmp_dir/bezelproject.list"
    download "https://api.github.com/repos/thebezelproject/bezelprojectsa-$bezelproject_name/git/trees/master?recursive=true" "$system_tmp_dir/bezelprojectsa.list"

    # Get the list of roms available in Theme-style repo
    declare -A themeRoms
    while read config_file; do
      local rom_name=$(basename "$config_file" '.cfg')
      themeRoms["$rom_name"]=1
    done < <(grep -oE "[^/]+.cfg" "$system_tmp_dir/bezelproject.list" | sort | uniq)

    # Get the list of roms available in System-style repo
    declare -A systemRoms
    while read config_file; do
      local rom_name=$(basename "$config_file" '.cfg')
      systemRoms["$rom_name"]=1
    done < <(grep -oE "[^/]+.cfg" "$system_tmp_dir/bezelprojectsa.list" | sort | uniq)

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
        local encoded_rom_name=$(python -c 'import urllib, sys; print urllib.quote(sys.argv[1])' "$rom_name")

        # There's a lot of inconsistency between the System-Style and Theme-style repos.  If Theme-Style isn't
        # available, we fall back to System-Style.
        local bezelproject_overlay_url=""
        if [ "${themeRoms["$rom_name"]}" == '1' ]; then
          bezelproject_overlay_url="$bezelproject_base_url/$bezelproject_overlay_path"
        elif [ "${systemRoms["$rom_name"]}" == '1' ]; then
          bezelproject_overlay_url="$bezelprojectsa_base_url/$bezelproject_overlay_path"
        fi

        if [ -n "$bezelproject_overlay_url" ]; then
          download "$bezelproject_overlay_url/$encoded_rom_name.cfg" "$overlays_dir/$rom_name.cfg"
          download "$bezelproject_overlay_url/$encoded_rom_name.png" "$overlays_dir/$rom_name.png"

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
