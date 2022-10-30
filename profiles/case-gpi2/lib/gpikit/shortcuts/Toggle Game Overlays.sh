#!/bin/bash

# Toggles whether RetroArch overlays are displayed

retroarch_config_path=/opt/retropie/configs/all/retroarch.cfg
setting=input_overlay_enable

swap_config() {
  local from_value=$1
  local to_value=$2
  sed -i "s/^$setting *= *$from_value/$setting = $to_value/g" "$retroarch_config_path"
}

if grep -q "^$setting *= *true" "$retroarch_config_path"; then
  swap_config true false
  echo 'Overlays disabled'
else
  swap_config false true
  echo 'Overlays enabled'
fi
