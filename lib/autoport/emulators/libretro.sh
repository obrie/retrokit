#!/usr/bin/env bash

# Set up port index overrides for the provided device type
__setup_libretro() {
  local profile=$1
  local driver_name=$2
  local retroarch_driver_name
  if [ "$driver_name" == 'mouse' ]; then
    retroarch_driver_name=mouse
  elif [ "$driver_name" == 'joystick' ]; then
    retroarch_driver_name=joypad
  else
    return
  fi
  local retroarch_config_file=/dev/shm/retroarch.cfg

  # Remove any existing runtime overrides
  sed -i "/^input_player.*$retroarch_driver_name/d" "$retroarch_config_file"

  __match_players "$profile" "$driver_name"

  for player_index in "${player_indexes[@]}"; do
    local device_index=${players["$player_index/device_index"]}
    local device_type=${players["$player_index/device_type"]}

    echo "Player $player_index: index $device_index"

    # Retroarch config contains:
    # * Port mapping
    echo "input_player${player_index}_${retroarch_driver_name}_index = \"$device_index\"" >> "$retroarch_config_file"

    # Remap config contains:
    # * Device type
    if [ -n "$device_type" ]; then
      local libretro_core_name=$(__get_libretro_core_name)
      if [ -z "$libretro_core_name" ]; then
        echo "Failed to find core name for $libretro_core_filename.so"
        return 1
      fi

      local remap_dir=$(__find_setting "$retropie_configs_dir/$system/retroarch.cfg" '' input_remapping_directory || "$retropie_configs_dir/$system")
      local core_remap_dir="$remap_dir/$libretro_core_name"
      local remap_file="$core_remap_dir/$rom_name.rmp"
      local remap_backup_file="$remap_file.autoport"
      local core_remap_file="$core_remap_dir/$libretro_core_name.rmp"

      # We're either going to edit the exiting game-specific remap file,
      # use the emulator one as a base, or start from scratch
      if [ -f "$remap_file" ]; then
        cp -v "$remap_file" "$remap_backup_file"
      else
        mkdir -p "$core_remap_dir"
        touch "$remap_backup_file.missing"

        if [ -f "$core_remap_file" ]; then
          cp "$core_remap_file" "$remap_file"
        fi
      fi

      echo "input_libretro_device_p${player_index} = \"$device_type\"" >> "$remap_file"
    fi
  done
}

__restore_libretro() {
  local libretro_core_name=$(__get_libretro_core_name)
  if [ -z "$libretro_core_name" ]; then
    echo "Failed to find core name for $libretro_core_filename.so"
    return 1
  fi

  local remap_dir=$(__find_setting "$retropie_configs_dir/$system/retroarch.cfg" '' input_remapping_directory || "$retropie_configs_dir/$system")
  local core_remap_dir="$remap_dir/$libretro_core_name"
  if [ ! -d "$core_remap_dir" ]; then
    return
  fi

  local remap_file="$core_remap_dir/$rom_name.rmp"
  local remap_backup_file="$remap_file.autoport"

  if [ -f "$remap_backup_file" ]; then
    # Restore the original game-specific remap
    mv -v "$remap_backup_file" "$remap_file"
  elif [ -f "$remap_backup_file.missing" ]; then
    # Delete the remap files since they were never there to begin with
    rm -fv "$remap_file" "$remap_backup_file.missing"
  fi

  # Remove empty folders
  if [ -z "$(ls -A "$core_remap_dir")" ]; then
    rmdir -v "$core_remap_dir"
  fi
}

# Looks up the name of the libretro core that's being launched
__get_libretro_core_name() {
  local libretro_core_filename=$(echo "$rom_command" | grep -oE "[^/]+\.so" | grep -oE "^[^.]+")
  local libretro_core_info_path="$retropie_configs_dir/all/retroarch/cores/$libretro_core_filename.info"
  local libretro_core_name
  if [ -f "$libretro_core_info_path" ]; then
    libretro_core_name=$(__find_setting "$libretro_core_info_path" '' corename)
  else
    # In some cases we have to fall back to a manual mapping
    declare -A mappings=(
      [mamearcade2016_libretro]=mame2016_libretro
    )

    libretro_core_name=${mappings[$libretro_core_filename]}
  fi

  if [ -n "$libretro_core_name" ]; then
    libretro_core_name=${libretro_core_name// (Git)/}
    echo "$libretro_core_name"
  else
    return 1
  fi
}
