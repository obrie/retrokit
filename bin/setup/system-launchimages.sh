#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  launch_theme=$(setting '.themes.launch_theme')
  launch_images_base_url=$(setting ".themes.library[] | select(.name == \"$launch_theme\") | .launch_images_base_url")

  local system_image_name=$system
  if [ "$system_image_name" == "megadrive" ]; then
    system_image_name="genesis"
  fi
  
  download "$(printf "$launch_images_base_url" "$system_image_name")" "$retropie_system_config_dir/launching-extended.png"
}

uninstall() {
  echo 'No uninstall for launch images'
}

"$1" "${@:3}"
