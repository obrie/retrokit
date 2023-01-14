#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-roms-retroarch'
setup_module_desc='Configure game-specific retroarch configurations and core options'

retroarch_config_dir=$(get_retroarch_path 'rgui_config_directory')
retroarch_remapping_dir=$(get_retroarch_path 'input_remapping_directory')
retroarch_remapping_dir=${retroarch_remapping_dir%/}

configure() {
  restore

  __configure_retroarch_configs
  __configure_retroarch_remappings
  __configure_retroarch_core_options
}

# Game-specific retroarch configuration overrides
# 
# Note that overrides get defined under the retroarch emulator's directory
# instead of the RetroPie roms directory.  This is because the `--appendconfig`
# option that's used by RetroPie cannot override configurations defined in an
# existing built-in RetroArch configuration, which makes configurations a pain
# to manage otherwise.
__configure_retroarch_configs() {
  local rom_dirs=$(system_setting 'select(.roms) | .roms.dirs[] | .path')
  if [ -z "$rom_dirs" ]; then
    return
  fi

  # Merge in rom-specific overrides
  while IFS=» read -r rom_name core_name core_option_prefix library_name control_type peripherals override_file; do
    # Retroarch emulator-specific config
    local target_path="$retroarch_config_dir/$library_name/$rom_name.cfg"
    local paths_to_merge=()

    # Peripheral overrides
    for peripheral in ${peripherals//,/ }; do
      paths_to_merge+=("{system_config_dir}/retroarch-$peripheral.cfg")
    done

    # Control type overrides
    if [ -n "$control_type" ]; then
      paths_to_merge+=("{system_config_dir}/retroarch-$control_type.cfg")
    fi

    if [ -n "$override_file" ]; then
      paths_to_merge+=("$override_file")
    fi

    # Merge in any valid paths
    for path in "${paths_to_merge[@]}"; do
      if any_path_exists_cached "$path"; then
        ini_merge "$path" "$target_path" backup=false
      fi
    done
  done < <(__list_libretro_roms 'cfg')
}

# Games-specific controller mapping overrides
__configure_retroarch_remappings() {
  while IFS=» read -r rom_name core_name core_option_prefix library_name control_type peripherals override_file; do
    if [ -z "$override_file" ]; then
      continue
    fi

    # Emulator-specific remapping file
    ini_merge "$override_file" "$retroarch_remapping_dir/$library_name/$rom_name.rmp" backup=false overwrite=true
  done < <(__list_libretro_roms 'rmp')
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
__configure_retroarch_core_options() {
  local system_core_options_path=$(get_retroarch_path 'core_options_path')

  while IFS=» read -r rom_name core_name core_option_prefix library_name control_type peripherals override_file; do
    # Retroarch emulator-specific config
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    local target_path="$emulator_config_dir/$rom_name.opt"

    local paths_to_merge=()

    # Peripheral overrides
    for peripheral in ${peripherals//,/ }; do
      paths_to_merge+=("{system_config_dir}/retroarch-core-options-$peripheral.cfg")
    done

    # Control type overrides
    if [ -n "$control_type" ]; then
      paths_to_merge+=("{system_config_dir}/retroarch-core-options-$control_type.cfg")
    fi

    if [ -n "$override_file" ]; then
      paths_to_merge+=("$override_file")
    fi

    # Merge in any valid paths
    local initialized_file=false
    for path in "${paths_to_merge[@]}"; do
      if any_path_exists_cached "$path"; then
        if [ "$initialized_file" == 'false' ]; then
          mkdir -p "$emulator_config_dir"

          # Copy over existing core overrides so we don't just get the
          # core defaults
          echo "Merging $core_option_prefix system overrides to $target_path"
          cp -v "$system_core_options_path" "$target_path"

          initialized_file=true
        fi

        ini_merge "$path" "$target_path" backup=false
      fi
    done

    # Allowlist options specific to this core
    if [ -f "$target_path" ]; then
      sed -i -n "/^$core_option_prefix[-_]/p" "$target_path"

      # If the file is empty after this, remove it
      if [ ! -s "$target_path" ]; then
        rm -fv "$target_path"
      fi
    fi
  done < <(__list_libretro_roms 'opt')
}

__list_libretro_roms() {
  local extension=$1

  # Load core/library info for the emulators
  load_emulator_data

  # Load which overrides are available
  declare -Ag override_files
  while read override_file; do
    local override_name=$(basename "$override_file" ".$extension")
    override_files["$override_name"]=$override_file
  done < <(each_path '{system_config_dir}/retroarch' find '{}' -name "*.$extension")

  # Track which playlists we've installed so we don't do it twice
  declare -A installed_playlists

  while IFS=» read -r rom_name playlist_name title parent_name group_name rom_path emulator controls peripherals; do
    # Look up emulator attributes as those are the important ones
    # for configuration purposes
    emulator=${emulator:-default}
    local core_name=${emulators["$emulator/core_name"]}
    local core_option_prefix=${emulators["$emulator/core_option_prefix"]}
    local library_name=${emulators["$emulator/library_name"]}
    if [ -z "$core_name" ] || [ -z "$library_name" ]; then
      continue
    fi

    # Controls / Peripherals
    local control_type=$(get_primary_control "$controls")

    local target_name
    if [ -n "$playlist_name" ]; then
      if [ "${installed_playlists["$playlist_name"]}" ]; then
        # We've already processed this playlist -- don't do it again
        continue
      fi

      # Generate a config for the playlist
      installed_playlists["$playlist_name"]=1
      target_name=$playlist_name
    else
      # Generate a config for single-disc games
      target_name=$rom_name
    fi

    # Find a file for either the rom or its group.  Priority order:
    # * ROM Name
    # * ROM Disc Name
    # * ROM Title
    # * ROM Playlist Name
    local override_file=""
    local filename
    for filename in "$rom_name" "$playlist_name" "$title" "$parent_name" "$group_name"; do
      if [ -n "$filename" ]; then
        override_file=${override_files["$filename"]}
        if [ -n "$override_file" ]; then
          break
        fi
      fi
    done

    echo "${target_name}»${core_name}»${core_option_prefix}»${library_name}»${control_type}»${peripherals}»${override_file}"
  done < <(romkit_cache_list | jq -r '[.name, .playlist.name, .title, .parent.name, .group.name, .path, .emulator, (.controls | join(",")), (.peripherals | join(","))] | join("»")')
}

restore() {
  while read -r library_name; do
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      # Remove core options
      find "$emulator_config_dir" -name '*.opt' -exec rm -fv '{}' +

      # Remove retroarch config overrides
      while read rom_config_path; do
        if grep -qvF input_overlay "$rom_config_path"; then
          # Keep input_overlay as that's managed by system-roms-overlays
          echo "Removing overrides from $rom_config_path"
          sed -i '/^input_overlay[ =]/!d' "$rom_config_path"

          if [ ! -s "$rom_config_path" ]; then
            rm -fv "$rom_config_path"
          fi
        fi
      done < <(find "$emulator_config_dir" -name '*.cfg' -not -name "$library_name.cfg")
    fi

    # Remove retroarch mappings
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    if [ -d "$emulator_remapping_dir" ]; then
      find "$emulator_remapping_dir" -name '*.rmp' -not -name "$library_name.rmp*" -exec rm -fv '{}' +
    fi
  done < <(get_core_library_names)
}

setup "${@}"
