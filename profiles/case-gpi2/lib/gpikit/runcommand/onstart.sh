#!/bin/bash

retroarch_config_file=/opt/retropie/configs/all/retroarch.cfg

function update_retroarch_setting() {
  local key=$1
  local value=$2
  if grep -q "^$key *=.*\$" "$retroarch_config_file"; then
    # Replace value
    sed -i "s/^$key *=.*\$/$key = $value/g" "$retroarch_config_file"
  else
    # Add value
    echo "$key = $value" >> "$retroarch_config_file"
  fi
}

screen_dimensions=$(fbset -s | grep -E "^mode" | grep -oE "[0-9]+x[0-9]+")
IFS=x read -r screen_width screen_height <<< "$screen_dimensions"

# Switch the display of RetroArch overlays based on the resolution (typically HDMI vs. LCD)
if [ $((screen_width * 9)) == $((screen_height * 16)) ]; then
  update_retroarch_setting input_overlay_enable true
else
  update_retroarch_setting input_overlay_enable false
fi
