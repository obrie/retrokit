#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

overlays_dir="$retroarch_config_dir/overlay"

install() {
  while IFS='^' read repo branch default_image_path vertical_image_path ; do
    branch=${branch:-master}
    local base_url="https://github.com/$repo/raw/$branch"

    # Install default overlay configuration
    if [ -n "$default_image_path" ]; then
      download "$base_url/$default_image_path" "$overlays_dir/$system.png"
      create_overlay_config "$overlays_dir/$system.cfg" "$system.png"
    fi

    # For systems that have vertical orientations (like MAME), install the
    # vertical configuration
    if [ -n "$vertical_image_path" ]; then
      download "$base_url/$default_image_path" "$overlays_dir/$system-vertical.png"
      create_overlay_config "$overlays_dir/$system-vertical.cfg" "$system-vertical.png"
    fi
  done < <(system_setting '.overlays.repos[]? | [.repo, .branch, .default, .vertical] | join("^")')
}

uninstall() {
  echo "Deleting $overlays_dir/$system*.cfg/png"
  rm -f "$overlays_dir/$system.cfg" "$overlays_dir/$system.png" "$overlays_dir/$system-vertical.cfg" "$overlays_dir/$system-vertical.png"
}

"$1" "${@:3}"
