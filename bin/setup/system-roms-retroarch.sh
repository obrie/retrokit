#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

find_overrides() {
  local extension=$1

  if [ -d "$system_config_dir/retroarch" ]; then
    # Load core/library info for the emulators
    load_emulator_data

    while IFS="^" read rom_name parent_name emulator; do
      emulator=${emulator:-default}

      # Find a file for either the rom or its parent
      local override_file=""
      if [ -f "$system_config_dir/retroarch/$rom_name.$extension" ]; then
        override_file="$system_config_dir/retroarch/$rom_name.$extension"
      elif [ -f "$system_config_dir/retroarch/$parent_name.$extension" ]; then
        override_file="$system_config_dir/retroarch/$parent_name.$extension"
      fi

      if [ -n "$override_file" ]; then
        # Look up emulator attributes as those are the important ones
        # for configuration purposes
        local core_name=${emulators["$emulator/core_name"]}
        local library_name=${emulators["$emulator/library_name"]}

        # Make sure this is a libretro core
        if [ -n "$core_name" ] && [ -n "$library_name" ]; then
          echo "$rom_name$tab$override_file$tab$core_name$tab$library_name"
        fi
      fi
    done < <(romkit_cache_list | jq -r '[.name, .parent, .emulator] | join("^")')
  fi
}

# Game-specific libretro core overrides
# (https://retropie.org.uk/docs/RetroArch-Core-Options/)
install_retroarch_core_options() {
  # Figure out where the core options live for this system
  local core_options_path=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'core_options_path' 2>/dev/null | tr -d '"' || true)
  if [ -z "$core_options_path" ]; then
    core_options_path='/opt/retropie/configs/all/retroarch-core-options.cfg'
  fi

  declare -A installed_files
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
    grep -E "^$core_name" "$core_options_path" > "$target_path" || true

    # Merge in game-specific overrides
    echo "Merging ini $override_file to $target_path"
    crudini --merge "$target_path" < "$override_file"
    installed_files["$target_path"]=1
  done < <(find_overrides 'opt')

  # Remove old, unused emulator overlay configs
  while read library_name; do
    while read path; do
      [ ! "${installed_files["$path"]}" ] && rm -v "$path"
    done < <(find "$retroarch_config_dir/config/$library_name" -name '*.opt')
  done < <(get_core_library_names)
}

# Games-specific controller mapping overrides
install_retroarch_remappings() {
  local remapping_dir=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'input_remapping_directory' 2>/dev/null || true)

  if [ -n "$remapping_dir" ]; then
    remapping_dir=${remapping_dir//\"/}
    
    declare -A installed_files
    while IFS="$tab" read rom_name override_file core_name library_name; do
      # Emulator-specific remapping directory
      local emulator_remapping_dir="$remapping_dir$library_name"
      mkdir -p "$emulator_remapping_dir"

      ini_merge "$override_file" "$emulator_remapping_dir/$rom_name.rmp"
      installed_files["$emulator_remapping_dir/$rom_name.rmp"]=1
    done < <(find_overrides 'rmp')

    # Remove unused remappings
    while read library_name; do
      while read path; do
        [ ! "${installed_files["$path"]}" ] && rm -v "$path"
      done < <(find "$remapping_dir$library_name" -name '*.rmp')
    done < <(get_core_library_names)
  fi
}

# Game-specific retroarch configuration overrides
install_retroarch_configs() {
  declare -A installed_files
  while IFS="$tab" read rom_name override_file core_name library_name; do
    local target_file="$HOME/RetroPie/roms/$system/$rom_name.cfg"

    ini_merge "$override_file" "$target_file"
    installed_files["$target_file"]=1
  done < <(find_overrides 'cfg')

  # Remove unused configs
  while read path; do
    [ ! "${installed_files["$path"]}" ] && rm -v "$path"
  done < <(find "$HOME/RetroPie/roms/$system" -name '*.cfg')
}

install() {
  install_retroarch_configs
  install_retroarch_remappings
  install_retroarch_core_options
}

uninstall() {
  # Remove core options
  while read library_name; do
    local retroarch_emulator_config_dir="$retroarch_config_dir/config/$library_name"
    if [ -d "$retroarch_emulator_config_dir" ]; then
      find "$retroarch_emulator_config_dir" -name '*.opt' -exec rm -fv "{}" \;
    fi
  done < <(get_core_library_names)

  # Remove retroarch remappings
  local remapping_dir=$(crudini --get "$retropie_system_config_dir/retroarch.cfg" '' 'input_remapping_directory' 2>/dev/null || true)
  if [ -n "$remapping_dir" ]; then
    remapping_dir=${remapping_dir//\"/}
    if [ -d "$remapping_dir" ]; then
      find "$remapping_dir" -name '*.rmp' -exec rm -fv "{}" \;
    fi
  fi

  # Remove retroarch configs
  if [ -d "$HOME/RetroPie/roms/$system/" ]; then
    find "$HOME/RetroPie/roms/$system/" -name '*.cfg' -exec rm -fv "{}" \;
  fi
}

"$1" "${@:3}"
