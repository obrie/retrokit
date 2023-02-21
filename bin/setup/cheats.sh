#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='cheats'
setup_module_desc='Retroarch cheats for use from the frontend'

build() {
  local cheats_zip="$tmp_dir/cheats.zip"
  download 'http://buildbot.libretro.com/assets/frontend/cheats.zip' "$cheats_zip"
  unzip -o "$cheats_zip" -d "$retropie_configs_dir/all/retroarch/cheats/"
}

remove() {
  rm -rfv "$retropie_configs_dir/all/retroarch/cheats/"*
}

setup "${@}"
