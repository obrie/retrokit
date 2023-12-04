#!/usr/bin/env bash

# Sets up a *single* joystick based on the highest priority match.
__setup_ppsspp() {
  local profile=$1
  local driver_name=$2
  [[ "$driver_name" =~ mouse|keyboard ]] && return

  local config_file="$retropie_configs_dir/psp/PSP/SYSTEM/controls.ini"
  local device_config_file=$(__prepare_config_overwrite "$profile" joystick "$config_file")
  if [ -z "$device_config_file" ]; then
    return
  fi

  # Remove joystick configurations
  sed -i 's/10-[0-9]*\|,//g' "$config_file"

  # Merge in those from the device
  while read key separator value; do
    # Merge with existing value
    sed -i "/^$key *= *1/ s/\$/,$value/" "$config_file"

    # ...or set on its own
    sed -i "/^$key *= *\$/ s/\$/$value/" "$config_file"
  done < <(cat "$device_config_file" | grep -Ev '^ *#')
}

__restore_ppsspp() {
  __restore_joystick_config "$retropie_configs_dir/psp/PSP/SYSTEM/controls.ini"
}
