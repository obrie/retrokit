#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/hiscores'
setup_module_desc='Hiscore support for MAME'

build() {
  # Hiscores: FBNeo (already installed)

  # Hiscores: MAME (pre 2016)
  download 'https://github.com/libretro/mame2010-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2010/hiscore.dat"

  # Hiscores: MAME (post 2016)
  download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2015/hiscore.dat"
  download 'https://github.com/libretro/mame2016-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2016/hiscore.dat"
}

remove() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame2010/hiscore.dat" \
    "$HOME/RetroPie/BIOS/mame2015/hiscore.dat" \
    "$HOME/RetroPie/BIOS/mame2016/hiscore.dat"
}

setup "${@}"
