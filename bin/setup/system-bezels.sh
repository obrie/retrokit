#!/bin/bash

set -ex

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/system-common.sh"

install() {
  local name=$(system_setting '.themes.bezel')
  local bezelproject_bin="$HOME/RetroPie/retropiemenu/bezelproject.sh"
  
  if [ ! -d "$retroarch_config_dir/overlay/GameBezels/$name" ]; then
    "$bezelproject_bin" install_bezel_packsa "$name" "thebezelproject"
    "$bezelproject_bin" install_bezel_pack "$name" "thebezelproject"
  fi
}

uninstall() {
  if [ ! -d "$retroarch_config_dir/overlay/GameBezels/$name" ]; then
    "$bezelproject_bin" uninstall_bezel_packsa "$name" "thebezelproject"
    "$bezelproject_bin" uninstall_bezel_pack "$name" "thebezelproject"
  fi
}

"${@:2}"
