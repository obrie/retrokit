#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local launch_theme=$(setting '.themes.launch_theme')
  local launch_images_base_url=$(setting ".themes.library[] | select(.name == \"$launch_theme\") | .launch_images_base_url")
  local system_theme=$(system_setting '.themes.system // .system')
  
  if [ "$system" != 'pc' ]; then
    # Currently no support for PC launch images due to keyboard issues
    download "$(printf "$launch_images_base_url" "$system_theme")" "$retropie_system_config_dir/launching-extended.png"
  fi
}

uninstall() {
  echo 'No uninstall for launch images'
}

"$1" "${@:3}"
