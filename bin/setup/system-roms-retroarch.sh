#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-retroarch'
setup_module_desc='Configure game-specific retroarch configurations and core options'

retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
retroarch_remapping_dir=${retroarch_remapping_dir%/}

configure() {
  __configure_retroarch_configs
  __configure_retroarch_remappings
  __configure_retroarch_core_options
}

# Game-specific retroarch configuration overrides
__configure_retroarch_configs() {
  local rom_dirs=$(system_setting 'select(.roms) | .roms.dirs[] | .path')
  if [ -z "$rom_dirs" ]; then
    return
  fi

  # Create cfg files
  declare -A installed_files
  while IFS=$'\t' read -r rom_name override_file core_name library_name; do
    while read -r rom_dir; do
      if ls "$rom_dir/$rom_name".* >/dev/null 2>&1; then
        local target_file="$rom_dir/$rom_name.cfg"

        ini_merge "$override_file" "$target_file" backup=false overwrite=true
        installed_files["$target_file"]=1
      fi
    done < <(echo "$rom_dirs")
  done < <(__find_overrides 'cfg')

  # Remove unused configs
  while read -r rom_dir; do
    while read -r path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$rom_dir" -maxdepth 1 -name '*.cfg')
  done < <(echo "$rom_dirs")
}

# Games-specific controller mapping overrides
__configure_retroarch_remappings() {
  declare -A installed_files
  while IFS=$'\t' read -r rom_name override_file core_name library_name; do
    # Emulator-specific remapping directory
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    mkdir -p "$emulator_remapping_dir"

    ini_merge "$override_file" "$emulator_remapping_dir/$rom_name.rmp" backup=false overwrite=true
    installed_files["$emulator_remapping_dir/$rom_name.rmp"]=1
  done < <(__find_overrides 'rmp')

  # Remove unused remappings
  while read -r library_name; do
    [ ! -d "$retroarch_remapping_dir/$library_name" ] && continue

    while read -r path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$retroarch_remapping_dir/$library_name" -name '*.rmp')
  done < <(get_core_library_names)
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
__configure_retroarch_core_options() {
  local system_core_options_path=$(get_retroarch_path 'core_options_path')

  declare -A installed_files
  while IFS=$'\t' read -r rom_name override_file core_name library_name; do
    # Retroarch emulator-specific config
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    mkdir -p "$emulator_config_dir"

    # Copy over existing core overrides so we don't just get the
    # core defaults
    local target_path="$emulator_config_dir/$rom_name.opt"
    rm -fv "$target_path"
    echo "Merging $core_name system overrides to $target_path"
    grep -E "^$core_name" "$system_core_options_path" > "$target_path" || true

    # Merge in game-specific overrides
    ini_merge "$override_file" "$target_path" backup=false
    installed_files["$target_path"]=1
  done < <(__find_overrides 'opt')

  # Remove old, unused core options
  while read -r library_name; do
    [ ! -d "$retroarch_config_dir/$library_name" ] && continue

    while read -r path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$retroarch_config_dir/$library_name" -name '*.opt')
  done < <(get_core_library_names)
}

# Find overrides with the given extension in retrokit.  Possible extensions:
# * cfg (retroarch configuration)
# * opt (emulator core options)
# * rmp (controller remappings)
__find_overrides() {
  local extension=$1

  if any_path_exists '{system_config_dir}/retroarch'; then
    # Load core/library info for the emulators
    load_emulator_data

    # Load which overrides are available
    declare -A override_files
    while read override_file; do
      local override_name=$(basename "$override_file" ".$extension")
      override_files["$override_name"]=$override_file
    done < <(each_path '{system_config_dir}/retroarch' find '{}' -name "*.$extension")

    # Track which playlists we've installed so we don't do it twice
    declare -A installed_playlists

    while IFS=» read -r rom_name disc title playlist_name parent_name parent_disc parent_title emulator; do
      emulator=${emulator:-default}

      # Find a file for either the rom or its parent.  Priority order:
      # * ROM Name
      # * ROM Disc Name
      # * ROM Title
      # * ROM Playlist Name
      local override_file=""
      for filename in "$rom_name" "$disc" "$title" "$playlist_name" "$parent_name" "$parent_disc" "$parent_title"; do
        if [ -n "$filename" ]; then
          override_file=${override_files["$filename"]}
          if [ -n "$override_file" ]; then
            break
          fi
        fi
      done

      if [ -n "$override_file" ]; then
        # Look up emulator attributes as those are the important ones
        # for configuration purposes
        local core_name=${emulators["$emulator/core_name"]}
        local library_name=${emulators["$emulator/library_name"]}

        # Make sure this is a libretro core
        if [ -n "$core_name" ] && [ -n "$library_name" ]; then
          if [ -z "$playlist_name" ]; then
            # Generate a config for single-disc games
            echo "$rom_name"$'\t'"$override_file"$'\t'"$core_name"$'\t'"$library_name"
          elif [ ! "${installed_playlists["$playlist_name"]}" ]; then
            # Generate a config for the playlist
            installed_playlists["$playlist_name"]=1
            echo "$playlist_name"$'\t'"$override_file"$'\t'"$core_name"$'\t'"$library_name"
          fi
        fi
      fi
    done < <(romkit_cache_list | jq -r '[.name, .disc, .title, .playlist.name, .parent.name, .parent.disc, .parent.title, .emulator] | join("»")')
  fi
}

restore() {
  while read -r library_name; do
    # Remove core options
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      find "$emulator_config_dir" -name '*.opt' -o -name '*.opt.rk-src*' -exec rm -fv '{}' +
    fi

    # Remove retroarch mappings
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    if [ -d "$emulator_remapping_dir" ]; then
      find "$emulator_remapping_dir" -name '*.rmp' -o -name '*.rmp.rk-src*' -exec rm -fv '{}' +
    fi
  done < <(get_core_library_names)

  # Remove retroarch configs
  while read -r rom_dir; do
    find "$rom_dir" -maxdepth 1 -name '*.cfg' -o -name '*.cfg.rk-src*' -exec rm -fv '{}' +
  done < <(system_setting '.roms.dirs[] | .path')
}

setup "$1" "${@:3}"
