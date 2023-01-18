#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-overlays'
setup_module_desc='System-specific default overlays to display for libretro emulators (lightgun compatible)'

retroarch_overlay_dir=$(get_retroarch_path 'overlay_directory')

configure() {
  if [ $(system_setting '.overlays | has("default")') == 'false' ]; then
    echo 'No overlays configured'
    restore
    return
  fi

  # Install default (horizontal) overlay configuration
  local default_image_url=$(system_setting '.overlays.default')
  if [ -n "$default_image_url" ]; then
    download "$default_image_url" "$retroarch_overlay_dir/$system.png"
    create_overlay_config "$retroarch_overlay_dir/$system.cfg" "$system.png"

    # For systems that have lightgun games, create a lightgun-specific version
    if __enable_lightgun_borders && __has_lightgun_titles; then
      outline_overlay_image "$retroarch_overlay_dir/$system.png" "$retroarch_overlay_dir/$system-lightgun.png"
      create_overlay_config "$retroarch_overlay_dir/$system-lightgun.cfg" "$system-lightgun.png"
    fi
  fi

  # For systems that have vertical orientations (like MAME), install the
  # vertical configuration
  local vertical_image_url=$(system_setting '.overlays.vertical')
  if [ -n "$vertical_image_url" ]; then
    download "$vertical_image_url" "$retroarch_overlay_dir/$system-vertical.png"
    create_overlay_config "$retroarch_overlay_dir/$system-vertical.cfg" "$system-vertical.png"
  fi
}

# Are lightgun borders enabled for this system?
__enable_lightgun_borders() {
  [ "$(setting '.overlays.lightgun_border.enabled')" == 'true' ]
}

# Does this system have lightgun games to play?
__has_lightgun_titles() {
  jq -r '.[] | select(.controls) | .controls | .[]' "$system_data_file" | grep -Eq '^lightgun$'
}

restore() {
  rm -fv \
    "$retroarch_overlay_dir/$system.cfg" \
    "$retroarch_overlay_dir/$system-vertical.cfg" \
    "$retroarch_overlay_dir/$system-lightgun.cfg"
}

remove() {
  rm -fv \
    "$retroarch_overlay_dir/$system.png"\
    "$retroarch_overlay_dir/$system-vertical.png" \
    "$retroarch_overlay_dir/$system-lightgun.png"
}

setup "${@}"
