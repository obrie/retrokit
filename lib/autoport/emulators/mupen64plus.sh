#!/usr/bin/env bash

# Rewrites the Input-SDL-Control{index} settings in mupen64plus.cfg based on the
# highest priority matches.
__setup_mupen64plus() {
  local profile=$1
  local driver_name=$2
  [[ "$driver_name" =~ mouse|keyboard ]] && return

  local config_file="$retropie_configs_dir/n64/mupen64plus.cfg"
  local config_backup_file="$config_file.autoport"
  local auto_config_file="$retropie_configs_dir/n64/InputAutoCfg.ini"

  __match_players "$profile" joystick
  if [ ${#player_indexes[@]} -eq 0 ]; then
    # No matches found, use defaults
    return
  fi

  # Create config backup (only if one doesn't already exist)
  cp -vn "$config_file" "$config_backup_file"

  local auto_config_keys=(
    'A Button'
    'AnalogDeadzone'
    'AnalogPeak'
    'B Button'
    'C Button D'
    'C Button L'
    'C Button R'
    'C Button U'
    'DPad D'
    'DPad L'
    'DPad R'
    'DPad U'
    'L Trig'
    'Mempark switch'
    'mouse'
    'plugged'
    'plugin'
    'R Trig'
    'Rumblepak switch'
    'Start'
    'X Axis'
    'Y Axis'
    'Z Trig'
  )

  for player_index in "${player_indexes[@]}"; do
    local device_index=${players["$player_index/device_index"]}
    local device_name=${devices["$device_index/name"]}
    local player_section="Input-SDL-Control$player_index"

    # Remove the existing section for this player
    sed -i "/^\[$player_section\]/, /\[/ { //"'!'"d }; /^\[$player_section\]/d" "$config_file"

    # Start the new section
    cat >> "$config_file" << _EOF_
[$player_section]
version = 2.000000
mode = 0
device = $device_index
name = "$device_name"
_EOF_

    # Add auto-configuration values
    for auto_config_key in "${auto_config_keys[@]}"; do
      local value=$(__find_setting "$auto_config_file" "$device_name" "$auto_config_key")
      echo "$auto_config_key = \"$value\"" >> "$config_file"
    done
  done
}

__restore_mupen64plus() {
  __restore_joystick_config "$retropie_configs_dir/n64/mupen64plus.cfg"
}
