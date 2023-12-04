#!/usr/bin/env bash

__setup_supermodel3() {
  local profile=$1
  local driver_name=$2
  [ "$driver_name" == 'keyboard' ] && return

  local config_file="$retropie_configs_dir/supermodel3/Supermodel.ini"
  local config_backup_file="$config_file.autoport"

  __setup_x11 "$driver_name"
  __match_players "$profile" "$driver_name"
  if [ ${#player_indexes[@]} -eq 0 ]; then
    # No matches found, use defaults
    return
  fi

  # Create config backup (only if one doesn't already exist)
  cp -vn "$config_file" "$config_backup_file"

  if [ "$driver_name" == 'mouse' ]; then
    # Replace mouse entries so we can differentiate between player and device index
    sed -i 's/MOUSE1/MOUSE01/g' "$config_file"
    sed -i 's/MOUSE2/MOUSE02/g' "$config_file"

    local emulator_device_index
    for player_index in 1 2; do
      local device_index=${players["$player_index/device_index"]}
      if [ -z "$device_index" ]; then
        continue
      fi

      # Change existing setting
      emulator_device_index=$((device_index+1))
      sed -i "s/MOUSE0${player_index}/MOUSE${emulator_device_index}/" "$config_file"
    done

    # If we didn't replace the 2nd mouse, assume that the 2nd mouse might start
    # at the next device index
    sed -i "s/MOUSE02/MOUSE$((emulator_device_index+1))/g" "$config_file"
  else
    # Remove all joystick configurations
    local joy_regex="JOY\+[^,\"]\+"
    sed -i "s/,$joy_regex//g" "$config_file"
    sed -i "s/$joy_regex,\?//g" "$config_file"

    local device_config_file
    local device_index
    for player_index in 1 2; do
      # Get the configuration file for a specific player number
      device_config_file=$(__device_config_for_player "$config_file" "$player_index" || echo "$device_config_file")
      device_index=${players["$player_index/device_index"]:-$((device_index+1))}
      local emulator_device_index=$((device_index+1))

      # Merge in those from the device
      while read key separator buttons; do
        # Find relevant buttons for this player
        local player_buttons=
        for button in ${buttons//,/ }; do
          if [[ "$button" == JOY${player_index}* ]]; then
            player_buttons="$player_buttons,$button"
          fi
        done

        if [ -z "$player_buttons" ]; then
          continue
        fi

        # Use the device index provided by autoport
        player_buttons=${player_buttons//JOY${player_index}/JOY${emulator_device_index}}

        sed -i "0,/^$key =/{s/^$key = \"\(.*\)\"/$key = \"\1$player_buttons\"/}" "$config_file"
      done < <(cat "$device_config_file" | grep -Ev '^ *[\[;]' | tr -d '"')

      # Remove leading commas (we skip figuring out whether we needed one above
      # in order to improve loop performance)
      sed -i 's/",/"/g' "$config_file"
    done
  fi
}

__restore_supermodel3() {
  __restore_joystick_config "$retropie_configs_dir/supermodel3/Supermodel.ini"
}
