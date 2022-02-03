#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

install() {
  local cheats_zip="$tmp_dir/cheats.zip"

  download 'http://buildbot.libretro.com/assets/frontend/cheats.zip' "$cheats_zip"
  unzip -o "$cheats_zip" -d '/opt/retropie/configs/all/retroarch/cheats/'
}

uninstall() {
  rm -rfv /opt/retropie/configs/all/retroarch/cheats/*
}

"${@}"
