#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-overlays'
setup_module_desc='System-specific default overlays to display for libretro emulators (lightgun compatible)'

retroarch_overlay_dir=$(get_retroarch_path 'overlay_directory')

configure() {
  if [ $(system_setting '.overlays | has("repos")') == 'false' ]; then
    echo 'No overlays configured'
    restore
    return
  fi

  while IFS=» read -r repo branch default_image_path vertical_image_path; do
    branch=${branch:-master}
    local base_url="https://github.com/$repo/raw/$branch"

    # Install default (horizontal) overlay configuration
    if [ -n "$default_image_path" ]; then
      download "$base_url/$default_image_path" "$retroarch_overlay_dir/$system.png"
      create_overlay_config "$retroarch_overlay_dir/$system.cfg" "$system.png"

      # For systems that have lightgun games, create a lightgun-specific version
      if __enable_lightgun_borders && __has_lightgun_titles; then
        outline_overlay_image "$retroarch_overlay_dir/$system.png" "$retroarch_overlay_dir/$system-lightgun.png"
        create_overlay_config "$retroarch_overlay_dir/$system-lightgun.cfg" "$system-lightgun.png"
      fi
    fi

    # For systems that have vertical orientations (like MAME), install the
    # vertical configuration
    if [ -n "$vertical_image_path" ]; then
      download "$base_url/$vertical_image_path" "$retroarch_overlay_dir/$system-vertical.png"
      create_overlay_config "$retroarch_overlay_dir/$system-vertical.cfg" "$system-vertical.png"
    fi
  done < <(system_setting '.overlays.repos[] | [.repo, .branch, .default, .vertical] | join("»")')
}

# Are lightgun borders enabled for this system?
__enable_lightgun_borders() {
  [ "$(setting '.overlays.lightgun_border.enabled')" == 'true' ]
}

# Does this system have lightgun games to play?
__has_lightgun_titles() {
  each_path '{config_dir}/emulationstation/collections/custom-Lightguns.tsv' cat '{}' | grep -Eq "^$system"$'\t'
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

setup "$1" "${@:3}"
