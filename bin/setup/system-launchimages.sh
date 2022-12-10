#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

setup_module_id='system-launchimages'
setup_module_desc='System-specific launch images to display while emulators are loading'

configure() {
  local launch_image_url=$(system_setting '.themes.launch_image')
  if [ "$launch_image_url" == 'false' ]; then
    echo 'No launch images configured'
    restore
    return
  fi

  # Identify the theme being used
  local launch_theme=$(setting '.themes.launch_theme')

  if [ -z "$launch_image_url" ]; then
    local launch_images_base_url=$(setting ".themes.library[] | select(.name == \"$launch_theme\") | .launch_images_base_url")

    # Get the name of the platform (not guaranteed to be the system's name)
    local default_platform=$(xmlstarlet select -t -m "*/system[name='$system']" -v 'platform' -n /etc/emulationstation/es_systems.cfg)
    local platform=$(ini_get '{config_dir}/retropie/platforms.cfg' '' "${system}_theme")
    platform=${platform:-$default_platform}
    platform=${platform//\"/}

    launch_image_url=$(render_template "$launch_images_base_url" platform="$platform")
  fi

  # Download the image (identified by theme in case the theme changes)
  local download_path="$retropie_system_config_dir/launching-extended-$launch_theme.png"
  download "$launch_image_url" "$download_path"

  # Promote it to the primary launch screen for the system
  ln_if_different "$download_path" "$retropie_system_config_dir/launching-extended.png"
}

restore() {
  # Remove just the symlink since this will disable the functionality
  rm -fv "$retropie_system_config_dir/launching-extended.png"
}

remove() {
  rm -fv "$retropie_system_config_dir/"launching-extended-*
}

setup "${@}"
