#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
retroarch_remapping_dir=${retroarch_remapping_dir//\"/}
retroarch_remapping_dir=${retroarch_remapping_dir%/}

find_overrides() {
  local extension=$1

  if [ -d "$system_config_dir/retroarch" ]; then
    # Load core/library info for the emulators
    load_emulator_data

    declare -A playlists

    while IFS='^' read rom_name disc title parent_name parent_disc parent_title emulator; do
      emulator=${emulator:-default}

      # Find a file for either the rom or its parent
      local override_file=""
      for filename in "$rom_name" "$disc" "$title" "$parent_name" "$parent_disc" "$parent_title"; do
        if [ -f "$system_config_dir/retroarch/$filename.$extension" ]; then
          override_file="$system_config_dir/retroarch/$filename.$extension"
          break
        fi
      done

      if [ -n "$override_file" ]; then
        # Look up emulator attributes as those are the important ones
        # for configuration purposes
        local core_name=${emulators["$emulator/core_name"]}
        local library_name=${emulators["$emulator/library_name"]}

        # Make sure this is a libretro core
        if [ -n "$core_name" ] && [ -n "$library_name" ]; then
          if has_disc_config "$rom_name"; then
            # Generate a config for either a single-disc game or, if configured,
            # individual discs
            echo "$rom_name$tab$override_file$tab$core_name$tab$library_name"
          fi

          # Generate a config for the playlist (if applicable)
          local playlist_name=$(get_playlist_name "$rom_name")
          if has_playlist_config "$rom_name" && [ ! "${playlists["$playlist_name"]}" ]
            playlists["$playlist_name"]=1
            echo "$playlist_name$tab$override_file$tab$core_name$tab$library_name"
          fi
        fi
      fi
    done < <(romkit_cache_list | jq -r '[.name, .disc, .title, .parent.name, .parent.disc, .parent.title, .emulator] | join("^")')
  fi
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
install_retroarch_core_options() {
  local core_options_path=$(get_retroarch_path 'core_options_path')

  declare -A installed_files
  while IFS="$tab" read rom_name override_file core_name library_name; do
    # Retroarch emulator-specific config
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    mkdir -p "$emulator_config_dir"

    # Back up the existing file
    local target_path="$emulator_config_dir/$rom_name.opt"
    backup_and_restore "$target_path"

    # Copy over existing core overrides so we don't just get the
    # core defaults
    touch "$target_path"
    grep -E "^$core_name" "$core_options_path" > "$target_path" || true

    # Merge in game-specific overrides
    echo "Merging ini $override_file to $target_path"
    crudini --merge "$target_path" < "$override_file"
    installed_files["$target_path"]=1
  done < <(find_overrides 'opt')

  # Remove old, unused emulator overlay configs
  while read library_name; do
    [ ! -d "$retroarch_config_dir/$library_name" ] && continue

    while read path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$retroarch_config_dir/$library_name" -name '*.opt')
  done < <(get_core_library_names)

  # Reinstall the game-specific retroarch core options for this system.
  # Yes, this might mean we install game-specific core options multiple
  # times, but it also means we don't have to worry about remembering to
  # re-run system-roms-retroarch after running this setupmodule
  # 
  # We might want to consider some sort of "depends" system in the future
  # so that this isn't hard-coded.
  if [ -z "$SKIP_DEPS" ] && [ "$system" == 'c64' ] && has_setupmodule 'systems/c64/roms-joystick_selections'; then
    "$bin_dir/setup.sh" install systems/c64/roms-joystick_selections
  fi
}

# Games-specific controller mapping overrides
install_retroarch_remappings() {
  declare -A installed_files
  while IFS="$tab" read rom_name override_file core_name library_name; do
    # Emulator-specific remapping directory
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    mkdir -p "$emulator_remapping_dir"

    ini_merge "$override_file" "$emulator_remapping_dir/$rom_name.rmp"
    installed_files["$emulator_remapping_dir/$rom_name.rmp"]=1
  done < <(find_overrides 'rmp')

  # Remove unused remappings
  while read library_name; do
    [ ! -d "$retroarch_remapping_dir/$library_name" ] && continue

    while read path; do
      [ "${installed_files["$path"]}" ] || rm -v "$path"
    done < <(find "$retroarch_remapping_dir/$library_name" -name '*.rmp')
  done < <(get_core_library_names)
}

# Game-specific retroarch configuration overrides
install_retroarch_configs() {
  local rom_dirs=$(system_setting 'select(.roms) | .roms.dirs[] | .path')
  if [ -z "$rom_dirs" ]; then
    return
  fi

  declare -A installed_files
  while IFS="$tab" read rom_name override_file core_name library_name; do
    while read rom_dir; do
      if ls "$rom_dir/$rom_name".* >/dev/null 2>&1; then
        local target_file="$rom_dir/$rom_name.cfg"

        ini_merge "$override_file" "$target_file"
        installed_files["$target_file"]=1
      fi
    done < <(echo "$rom_dirs")
  done < <(find_overrides 'cfg')

  # Remove unused configs
  while read rom_dir; do
    while read rom_path; do
      [ "${installed_files["$rom_path"]}" ] || rm -v "$rom_path"
    done < <(find "$rom_dir" -maxdepth 1 -name '*.cfg')
  done < <(echo "$rom_dirs")
}

install() {
  install_retroarch_configs
  install_retroarch_remappings
  install_retroarch_core_options
}

uninstall() {
  while read library_name; do
    # Remove core options
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      find "$emulator_config_dir" -name '*.opt' -o -name '*.opt.rk-src*' -exec rm -fv "{}" \;
    fi

    # Remove retroarch mappings
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    if [ -d "$emulator_remapping_dir" ]; then
      find "$emulator_remapping_dir" -name '*.rmp' -o -name '*.rmp.rk-src*' -exec rm -fv "{}" \;
    fi
  done < <(get_core_library_names)

  # Remove retroarch configs
  while read rom_dir; do
    find "$rom_dir" -maxdepth 1 -name '*.cfg' -o -name '*.cfg.rk-src*' -exec rm -fv "{}" \;
  done < <(system_setting '.roms.dirs[] | .path')
}

"$1" "${@:3}"
