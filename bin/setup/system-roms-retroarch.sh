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
  while IFS=» read -r rom_name core_name core_option_prefix library_name control_type peripherals override_paths_dsv; do
    # Retroarch emulator-specific config
    local target_path="$retroarch_config_dir/$library_name/$rom_name.cfg"
    local paths_to_merge=()

    # Peripheral overrides
    for peripheral in ${peripherals//,/ }; do
      paths_to_merge+=("{config_dir}/retroarch/retroarch-$peripheral.cfg")
      paths_to_merge+=("{system_config_dir}/retroarch-$peripheral.cfg")
    done

    # Control type overrides
    if [ -n "$control_type" ]; then
      paths_to_merge+=("{config_dir}/retroarch/retroarch-$control_type.cfg")
      paths_to_merge+=("{system_config_dir}/retroarch-$control_type.cfg")
    fi

    local override_paths
    IFS=» read -r -a override_paths <<< "$override_paths_dsv"
    paths_to_merge+=("${override_paths[@]}")

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
  while IFS=» read -r rom_name core_name core_option_prefix library_name control_type peripherals override_paths_dsv; do
    # Emulator-specific remapping file
    local target_path="$retroarch_remapping_dir/$library_name/$rom_name.rmp"

    local paths_to_merge
    IFS=» read -r -a paths_to_merge <<< "$override_paths_dsv"

    for path in "${paths_to_merge[@]}"; do
      ini_merge "$path" "$target_path" backup=false
    done
  done < <(__list_libretro_roms 'rmp')
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
__configure_retroarch_core_options() {
  local system_core_options_path=$(get_retroarch_path 'core_options_path')

  while IFS=» read -r rom_name core_name core_option_prefix library_name control_type peripherals override_paths_dsv; do
    # Retroarch emulator-specific config
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    local target_path="$emulator_config_dir/$rom_name.opt"

    local paths_to_merge=()

    # Peripheral overrides
    for peripheral in ${peripherals//,/ }; do
      paths_to_merge+=("{config_dir}/retroarch/retroarch-core-options-$peripheral.cfg")
      paths_to_merge+=("{system_config_dir}/retroarch-core-options-$peripheral.cfg")
    done

    # Control type overrides
    if [ -n "$control_type" ]; then
      paths_to_merge+=("{config_dir}/retroarch/retroarch-core-options-$control_type.cfg")
      paths_to_merge+=("{system_config_dir}/retroarch-core-options-$control_type.cfg")
    fi

    local override_paths
    IFS=» read -r -a override_paths <<< "$override_paths_dsv"
    paths_to_merge+=("${override_paths[@]}")

    # Merge in any valid paths
    local initialized_file=false
    for path in "${paths_to_merge[@]}"; do
      # Ensure the path contains overrides for this core -- otherwise no need to merge
      if ! any_path_exists_cached "$path" || ! each_path "$path" cat '{}' | grep -Eq "^$core_option_prefix[-_]"; then
        continue
      fi

      if [ "$initialized_file" == 'false' ]; then
        mkdir -p "$emulator_config_dir"

        # Copy over existing core overrides so we don't just get the
        # core defaults
        echo "Merging $core_option_prefix system overrides to $target_path"
        cp -v "$system_core_options_path" "$target_path"

        initialized_file=true
      fi

      ini_merge "$path" "$target_path" backup=false
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
  declare -Ag override_names
  while read override_file; do
    local override_name=$(basename "$override_file" ".$extension")
    override_names["$override_name"]=1
  done < <(each_path '{system_config_dir}/retroarch' find '{}' -name "*.$extension")

  # Track which playlists we've installed so we don't do it twice
  declare -A installed_playlists

  while IFS=» read -r rom_name disc_name playlist_name title parent_name group_name rom_path emulator controls peripherals; do
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

    # Find override files (lowest priority to highest priority)
    declare -A checked_overrides
    local override_paths=()
    for override_name in "$group_name" "$title" "$disc_name" "$parent_name" "$playlist_name" "$rom_name"; do
      if [ -n "$override_name" ] && [ "${override_names[$override_name]}" ] && [ ! "${checked_overrides[$override_name]}" ]; then
        local system_override_path="{system_config_dir}/retroarch/$override_name.$extension"
        local emulator_override_path="{system_config_dir}/retroarch/$library_name/$override_name.$extension"

        if any_path_exists "$system_override_path"; then
          override_paths+=("${system_override_path}")
        fi

        if any_path_exists "$emulator_override_path"; then
          override_paths+=("${emulator_override_path}")
        fi

        checked_overrides[$override_name]=1
      fi
    done
    local override_paths_delimited=$(IFS=» ; echo "${override_paths[*]}")

    echo "${target_name}»${core_name}»${core_option_prefix}»${library_name}»${control_type}»${peripherals}»${override_paths_delimited}"
  done < <(romkit_cache_list | jq -r '[.name, .disc, .playlist.name, .title, .parent.name, .group.name, .path, .emulator, (.controls | join(",")), (.peripherals | join(","))] | join("»")')
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
