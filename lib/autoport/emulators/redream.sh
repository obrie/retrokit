#!/usr/bin/env bash

# Rewrites the port{index} settings in redream.cfg based on the highest
# priority matches.
__setup_redream() {
  local profile=$1
  local driver_name=$2
  [[ "$driver_name" =~ mouse|keyboard ]] && return

  local config_file="$retropie_configs_dir/dreamcast/redream/redream.cfg"
  local config_backup_file="$config_file.autoport"

  # Determine if a keyboard is being configured
  local keyboard_limit=$(__setting "$keyboard_profile" 'keyboard_limit')
  keyboard_limit=${keyboard_limit:-0}

  __match_players "$profile" joystick
  if [ ${#player_indexes[@]} -eq 0 ] && [ $keyboard_limit -eq 0 ]; then
    # No matches found, use defaults
    return
  fi

  # Create config backup (only if one doesn't already exist)
  cp -vn "$config_file" "$config_backup_file"

  # Add keyboard entries
  for (( player_index=0; player_index<$keyboard_limit; player_index++ )); do
    echo "port${player_index}=dev:0,desc:auto,type:keyboard" >> "$config_file"
  done

  # Add joystick entries
  for player_index in "${player_indexes[@]}"; do
    local device_index=${players["$player_index/device_index"]}
    local device_type=${players["$player_index/device_type"]:-controller}
    local device_guid=${devices["$device_index/guid"]}

    # Indexes are offset by 4
    # * 0 = auto
    # * 1 = disabled
    # * 2 = keyboard
    # * 3 = unknown
    ((device_index+=4))

    # Players start at offset 0
    ((player_index-=1))
    ((player_index+=$keyboard_limit))

    echo "Player $player_index: index $device_index"

    # Remove existing setting
    sed -i "/^port${player_index}=/d" "$config_file"

    # Add new setting
    echo "port${player_index}=dev:${device_index},desc:${device_guid},type:${device_type}" >> "$config_file"
  done
}

__restore_redream() {
  local config_file="$retropie_configs_dir/dreamcast/redream/redream.cfg"
  local config_backup_file="$config_file.autoport"
  if [ ! -f "$config_backup_file" ]; then
    return
  fi

  # Remove override settings
  sed -i '/^port[0-9]\+=/d' "$config_file"

  # Add original settings
  sed -i -e '$a\' "$config_file"
  grep '^port[0-9]+=' "$config_backup_file" >> "$config_file"

  rm "$config_backup_file"
}
