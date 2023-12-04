#!/usr/bin/env bash

# Sets up a *single* joystick based on the highest priority match.
__setup_drastic() {
  local profile=$1
  local driver_name=$2
  [[ "$driver_name" =~ mouse|keyboard ]] && return

  local config_file="$retropie_configs_dir/nds/drastic/config/drastic.cfg"
  local device_config_file=$(__prepare_config_overwrite "$profile" joystick "$config_file")
  if [ -z "$device_config_file" ]; then
    return
  fi

  # Remove joystick configurations
  sed -i '/controls_b/d' "$config_file"

  # Merge in those from the device
  cat "$device_config_file" | tee -a "$config_file" >/dev/null
}

__restore_drastic() {
  local config_file="$retropie_configs_dir/nds/drastic/config/drastic.cfg"
  local config_backup_file="$config_file.autoport"
  if [ ! -f "$config_backup_file" ]; then
    return
  fi

  # Remove override settings
  sed -i '/controls_b/d' "$config_file"

  # Add original settings (removing windows newlines while we're at it)
  sed -i -e '$a\' "$config_file"
  grep 'controls_b' "$config_backup_file" >> "$config_file"

  rm "$config_backup_file"
}
