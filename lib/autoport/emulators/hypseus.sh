#!/usr/bin/env bash

# Sets up a *single* joystick based on the highest priority match.
__setup_hypseus() {
  local profile=$1
  local driver_name=$2
  [[ "$driver_name" =~ mouse|keyboard ]] && return

  local config_file="$retropie_configs_dir/daphne/hypinput.ini"
  local device_config_file=$(__prepare_config_overwrite "$profile" joystick "$config_file")
  if [ -z "$device_config_file" ]; then
    return
  fi

  # Remove joystick configurations (and default to 0)
  sed -i 's/^\([^ ]\+\) = \([^ ]\+\) \([^ ]\+\).*$/\1 = \2 \3 0/g' "$config_file"

  # Merge in those from the device
  while read key separator button axis; do
    local joystick_value=$button
    if [ -n "$axis" ]; then
      joystick_value="$joystick_value $axis"
    fi

    sed -i "s/^$key = \([^ ]\+\) \([^ ]\+\).*\$/$key = \1 \2 $joystick_value/g" "$config_file"
  done < <(cat "$device_config_file" | grep -Ev '^ *#')
}

__restore_hypseus() {
  __restore_joystick_config "$retropie_configs_dir/daphne/hypinput.ini"
}
