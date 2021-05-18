#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local use_launch_image=$(system_setting '.themes.launch_image // true')
  if [ "$use_launch_image" == 'true' ]; then
    local launch_theme=$(setting '.themes.launch_theme')
    local launch_images_base_url=$(setting ".themes.library[] | select(.name == \"$launch_theme\") | .launch_images_base_url")
    local default_platform=$(xmlstarlet select -t -m "*/system[name='$system']" -v 'platform' -n /etc/emulationstation/es_systems.cfg)
    local platform=$(crudini --get "$config_dir/emulationstation/platforms.cfg" '' "${system}_theme" 2>/dev/null || echo "$default_platform")
    platform=${platform//\"/}
    
    download "$(printf "$launch_images_base_url" "$platform")" "$retropie_system_config_dir/launching-extended.png"
  fi
}

uninstall() {
  echo 'No uninstall for launch images'
}

"$1" "${@:3}"
