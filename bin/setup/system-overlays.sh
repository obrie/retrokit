#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

retroarch_overlay_dir=$(get_retroarch_path 'overlay_directory')

install() {
  if [ $(system_setting '.overlays | has("repos")') == 'false' ]; then
    echo 'No overlays configured'
    uninstall
    return
  fi

  while IFS=» read -r repo branch default_image_path vertical_image_path; do
    branch=${branch:-master}
    local base_url="https://github.com/$repo/raw/$branch"

    # Install default overlay configuration
    if [ -n "$default_image_path" ]; then
      download "$base_url/$default_image_path" "$retroarch_overlay_dir/$system.png"
      create_overlay_config "$retroarch_overlay_dir/$system.cfg" "$system.png"

      # For systems that have lightgun games, create a lightgun-specific version
      if [ "$(setting '.overlays.lightgun_border.enabled')" == 'true' ] && grep -Eq "^$system"$'\t' "$config_dir/emulationstation/collections/custom-lightguns.tsv"; then
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

uninstall() {
  rm -fv "$retroarch_overlay_dir/$system.cfg"\
    "$retroarch_overlay_dir/$system.png"\
    "$retroarch_overlay_dir/$system-vertical.cfg"\
    "$retroarch_overlay_dir/$system-vertical.png" \
    "$retroarch_overlay_dir/$system-lightgun.cfg" \
    "$retroarch_overlay_dir/$system-lightgun.png"
}

"$1" "${@:3}"
