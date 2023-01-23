#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-overlays'
setup_module_desc='System-specific default overlays to display in supported emulators (lightgun compatible)'

base_overlay_dir=$(system_setting '.overlays.target')
if [ -z "$base_overlay_dir" ]; then
  base_overlay_dir=$(get_retroarch_path 'overlay_directory')
fi

configure() {
  if [ $(system_setting '.overlays | has("default")') == 'false' ]; then
    echo 'No overlays configured'
    restore
    return
  fi

  # Install default (horizontal) overlay configuration
  local default_image_url=$(system_setting '.overlays.default')
  if [ -n "$default_image_url" ]; then
    download "$default_image_url" "$base_overlay_dir/$system.png"
    if has_libretro_cores; then
      create_overlay_config "$base_overlay_dir/$system.cfg" "$system.png"
    fi

    # For systems that have lightgun games, create a lightgun-specific version
    if __enable_lightgun_borders && __has_lightgun_titles; then
      outline_overlay_image "$base_overlay_dir/$system.png" "$base_overlay_dir/$system-lightgun.png"
      if has_libretro_cores; then
        create_overlay_config "$base_overlay_dir/$system-lightgun.cfg" "$system-lightgun.png"
      fi
    fi
  fi

  # For systems that have vertical orientations (like MAME), install the
  # vertical configuration
  local vertical_image_url=$(system_setting '.overlays.vertical')
  if [ -n "$vertical_image_url" ]; then
    download "$vertical_image_url" "$base_overlay_dir/$system-vertical.png"
    if has_libretro_cores; then
      create_overlay_config "$base_overlay_dir/$system-vertical.cfg" "$system-vertical.png"
    fi
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
    "$base_overlay_dir/$system.cfg" \
    "$base_overlay_dir/$system-vertical.cfg" \
    "$base_overlay_dir/$system-lightgun.cfg"
}

remove() {
  rm -fv \
    "$base_overlay_dir/$system.png"\
    "$base_overlay_dir/$system-vertical.png" \
    "$base_overlay_dir/$system-lightgun.png"
}

setup "${@}"
