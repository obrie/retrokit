#!/bin/bash

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../common.sh"

setup_module_id='cheats'
setup_module_desc='Retroarch cheats for use from the frontend'

cheats_dir="$retropie_configs_dir/all/retroarch/cheats"

build() {
  if ! find "$cheats_dir" -type f -name '*.cht' | head -n1 | grep -q . || [ "$FORCE_UPDATE" == 'true' ]; then
    local cheats_zip="$tmp_ephemeral_dir/cheats.zip"
    download 'http://buildbot.libretro.com/assets/frontend/cheats.zip' "$cheats_zip"
    unzip -u "$cheats_zip" -d "$cheats_dir/"
  fi
}

remove() {
  rm -rfv "$cheats_dir/"*
}

setup "${@}"
