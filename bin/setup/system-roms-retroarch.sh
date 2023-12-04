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
  __configure_retroarch_nvram
}

# Game-specific retroarch configuration overrides
# 
# Note that overrides get defined under the retroarch emulator's directory
# instead of the RetroPie roms directory.  This is because the `--appendconfig`
# option that's used by RetroPie cannot override configurations defined in an
# existing built-in RetroArch configuration, which makes configurations a pain
# to manage otherwise.
__configure_retroarch_configs() {
  # Merge in rom-specific overrides
  while IFS=$field_delim read -r rom_name rom_path core_name core_option_prefix library_name extensions_dsv merge_paths_dsv; do
    # Retroarch emulator-specific config
    local target_file="$retroarch_config_dir/$library_name/$rom_name.cfg"
    local include_paths=()

    # Peripheral / control type overrides
    local extensions
    IFS=$item_delim read -r -a extensions <<< "$extensions_dsv"
    for extension in "${extensions[@]}"; do
      if any_path_exists_cached "{config_dir}/retroarch/retroarch-$extension.cfg"; then
        include_paths+=("$retropie_configs_dir/all/retroarch-$extension.cfg")
      fi

      if any_path_exists_cached "{system_config_dir}/retroarch-$extension.cfg"; then
        include_paths+=("$retropie_system_config_dir/retroarch-$extension.cfg")
      fi

      if any_path_exists_cached "{system_config_dir}/retroarch/$library_name/$library_name-$extension.cfg"; then
        include_paths+=("$retroarch_config_dir/$library_name/$library_name-$extension.cfg")
      fi
    done

    # Merge in any valid paths
    local merge_paths
    IFS=$item_delim read -r -a merge_paths <<< "$merge_paths_dsv"
    for merge_path in "${merge_paths[@]}"; do
      if any_path_exists_cached "$merge_path"; then
        ini_merge "$merge_path" "$target_file" backup=false comments='^#include '
      fi
    done

    # Include in any valid paths
    if [ ${#include_paths[@]} -gt 0 ]; then
      mkdir -p "$(dirname "$target_file")"
      echo '' >> "$target_file"

      for include_path in "${include_paths[@]}"; do
        echo "Including ini $include_path in $target_file"
        echo "#include \"$include_path\"" >> "$target_file"
      done
    fi
  done < <(__list_libretro_roms 'cfg')
}

# Games-specific controller mapping overrides
__configure_retroarch_remappings() {
  while IFS=$field_delim read -r rom_name rom_path core_name core_option_prefix library_name extensions_dsv merge_paths_dsv; do
    # Emulator-specific remapping file
    local target_file="$retroarch_remapping_dir/$library_name/$rom_name.rmp"

    # Game-specific paths
    local merge_paths
    IFS=$item_delim read -r -a merge_paths <<< "$merge_paths_dsv"

    # Control / Peripheral / Tag extension paths
    local extension_merge_paths=()
    local extensions
    IFS=$item_delim read -r -a extensions <<< "$extensions_dsv"
    for extension in "${extensions[@]}"; do
      extension_merge_paths+=("{system_config_dir}/retroarch/$library_name/$library_name-$extension.rmp")
    done

    # Find valid paths
    local valid_merge_paths=()
    for merge_path in "${extension_merge_paths[@]}" "${merge_paths[@]}"; do
      if any_path_exists_cached "$merge_path"; then
        valid_merge_paths+=("$merge_path")
      fi
    done

    if [ ${#valid_merge_paths[@]} -eq 0 ]; then
      continue
    fi

    # Merge in default, extension, and game paths
    for merge_path in "{system_config_dir}/retroarch/$library_name/$library_name.rmp" "${valid_merge_paths[@]}"; do
      ini_merge "$merge_path" "$target_file" backup=false
    done
  done < <(__list_libretro_roms 'rmp')
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
__configure_retroarch_core_options() {
  local global_core_options_file=${retroarch_path_defaults['core_options_path']}
  local tmp_core_options_file=$(mktemp -p "$tmp_ephemeral_dir")

  while IFS=$field_delim read -r rom_name rom_path core_name core_option_prefix library_name extensions_dsv merge_paths_dsv; do
    # Retroarch emulator-specific config
    local target_file="$retroarch_config_dir/$library_name/$rom_name.opt"

    # Game-specific paths
    local merge_paths
    IFS=$item_delim read -r -a merge_paths <<< "$merge_paths_dsv"

    # Control / Peripheral / Tag extension paths
    local extension_merge_paths=()
    local extensions
    IFS=$item_delim read -r -a extensions <<< "$extensions_dsv"
    for extension in "${extensions[@]}"; do
      extension_merge_paths+=(
        "{config_dir}/retroarch/retroarch-core-options-$extension.cfg"
        "{system_config_dir}/retroarch-core-options-$extension.cfg"
      )
    done

    # Find valid paths
    local valid_merge_paths=()
    for merge_path in "${extension_merge_paths[@]}" "${merge_paths[@]}"; do
      if each_path "$merge_path" cat '{}' | grep -Eq "^$core_option_prefix[-_]"; then
        valid_merge_paths+=("$merge_path")
      fi
    done

    if [ ${#valid_merge_paths[@]} -eq 0 ]; then
      continue
    fi

    # Merge in any valid paths
    for merge_path in "$global_core_options_file" '{config_dir}/retroarch/retroarch-core-options.cfg' '{system_config_dir}/retroarch-core-options.cfg' "${extension_merge_paths[@]}" "${merge_paths[@]}"; do
      each_path "$merge_path" cat '{}' | grep -E "^$core_option_prefix[-_]" > "$tmp_core_options_file" || true

      if [ -s "$tmp_core_options_file" ]; then
        echo "Merging $core_option_prefix core options from $merge_path to $target_file"
        ini_merge "$tmp_core_options_file" "$target_file" backup=false >/dev/null
      fi
    done

    sort -o "$target_file" "$target_file"
  done < <(__list_libretro_roms 'opt')
}

# Game-specific libretro nvram overrides
__configure_retroarch_nvram() {
  local rom_dirs
  readarray -t rom_dirs < <(system_setting 'select(.roms) | .roms.dirs[] | .path')

  for nvram_extension in nv nvmem nvmem2 eeprom; do
    while IFS=$field_delim read -r rom_name rom_path core_name core_option_prefix library_name extensions_dsv merge_paths_dsv; do
      if [ -z "$merge_paths_dsv" ]; then
        continue
      fi

      local target_file="$rom_path.$nvram_extension"

      # Use the highest priority source file (the last one detected)
      local source_files
      IFS=$item_delim read -r -a source_files <<< "$merge_paths_dsv"
      local source_file=${source_files[-1]}

      # Copy to primary ROM location (this isn't where the emulator will look it up, though)
      file_cp "$source_file" "$target_file" backup=false

      # Symlink to directories where the rom is installed
      local rom_filename=${rom_path##*/}
      local rom_dir
      for rom_dir in "${rom_dirs[@]}"; do
        local installed_path=$(find "$rom_dir" -mindepth 1 -maxdepth 1 -name "$rom_filename" -print -quit)
        if [ -n "$installed_path" ]; then
          file_ln "$target_file" "$installed_path.$nvram_extension"
        fi
      done
    done < <(__list_libretro_roms "$nvram_extension" 'nvram/')
  done
}

__list_libretro_roms() {
  local extension=$1
  local subfolder=$2

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

  while IFS=$field_delim read -r rom_name disc_name playlist_name title parent_name group_name rom_path emulator controls extensions_dsv; do
    # Look up emulator attributes as those are the important ones
    # for configuration purposes
    emulator=${emulator:-default}
    local core_name=${emulators["$emulator/core_name"]}
    local core_option_prefix=${emulators["$emulator/core_option_prefix"]}
    local library_name=${emulators["$emulator/library_name"]}
    if [ -z "$core_name" ] || [ -z "$library_name" ]; then
      continue
    fi

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

    # Add primary control type as a candidate config extension
    local control_type=$(get_primary_control "$controls")
    if [ -n "$control_type" ]; then
      if [ -n "$extensions_dsv" ]; then
        extensions_dsv="$item_delim$extensions_dsv"
      fi
      extensions_dsv="$control_type$extensions_dsv"
    fi

    # Find game-specific files to merge (lowest priority to highest priority)
    declare -A checked_overrides
    local merge_paths=()
    for override_name in "$group_name" "$title" "$disc_name" "$parent_name" "$playlist_name" "$rom_name"; do
      if [ -n "$override_name" ] && [ "${override_names[$override_name]}" ] && [ ! "${checked_overrides[$override_name]}" ]; then
        local system_override_path="{system_config_dir}/retroarch/$subfolder$override_name.$extension"
        local emulator_override_path="{system_config_dir}/retroarch/$library_name/$subfolder$override_name.$extension"

        if any_path_exists "$system_override_path"; then
          merge_paths+=("${system_override_path}")
        fi

        if any_path_exists "$emulator_override_path"; then
          merge_paths+=("${emulator_override_path}")
        fi

        checked_overrides[$override_name]=1
      fi
    done
    local merge_paths_dsv=$(IFS=$item_delim ; echo "${merge_paths[*]}")

    echo "${target_name}${field_delim}${rom_path}${field_delim}${core_name}${field_delim}${core_option_prefix}${field_delim}${library_name}${field_delim}${extensions_dsv}${field_delim}${merge_paths_dsv}"
  done < <(romkit_cache_list | jq -r '
    [
      .name,
      .disc,
      .playlist.name,
      .title,
      .parent.name,
      .group.name,
      .path,
      .emulator,
      (.controls | join(",")),
      ((.peripherals + .tags + .collections) | join("'$item_delim'"))
    ] | join("'$field_delim'")
  ')
}

restore() {
  while read -r library_name; do
    local emulator_config_dir="$retroarch_config_dir/$library_name"
    if [ -d "$emulator_config_dir" ]; then
      # Remove core options
      find "$emulator_config_dir" -name '*.opt' -exec rm -fv '{}' +

      # Remove retroarch config overrides
      while read rom_config_file; do
        if grep -qvF input_overlay "$rom_config_file"; then
          # Keep input_overlay as that's managed by system-roms-overlays
          echo "Removing overrides from $rom_config_file"
          sed -i '/^input_overlay[ =]/!d' "$rom_config_file"

          if [ ! -s "$rom_config_file" ]; then
            rm -fv "$rom_config_file"
          fi
        fi
      done < <(find "$emulator_config_dir" -name '*.cfg' -not -name "$library_name*.cfg")
    fi

    # Remove retroarch mappings
    local emulator_remapping_dir="$retroarch_remapping_dir/$library_name"
    if [ -d "$emulator_remapping_dir" ]; then
      find "$emulator_remapping_dir" -name '*.rmp' -not -name "$library_name.rmp*" -exec rm -fv '{}' +
    fi
  done < <(get_core_library_names)
}

setup "${@}"
