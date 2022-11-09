#!/bin/bash

# Toggles whether RetroArch overlays are displayed
toggle_overlays() {
  retroarch_config_path=/opt/retropie/configs/all/retroarch.cfg
  setting=input_overlay_enable

  if grep -q "^$setting *= *true" "$retroarch_config_path"; then
    __swap_config true false
    echo 'Overlays disabled'
  else
    __swap_config false true
    echo 'Overlays enabled'
  fi
}

__swap_config() {
  local from_value=$1
  local to_value=$2
  sed -i "s/^$setting *= *$from_value/$setting = $to_value/g" "$retroarch_config_path"
}

toggle_overlays
