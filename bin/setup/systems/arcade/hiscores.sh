#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

install() {
  # Hiscores: FBNeo (already installed)

  # Hiscores: MAME (pre 2016)
  download 'https://github.com/libretro/mame2010-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2010/hiscore.dat"

  # Hiscores: MAME (post 2016)
  download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2015/hiscore.dat"
  download 'https://github.com/libretro/mame2016-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2016/hiscore.dat"
}

uninstall() {
  rm -f "$HOME/RetroPie/BIOS/mame2016/hiscore.dat" "$HOME/RetroPie/BIOS/mame2010/hiscore.dat" "$HOME/RetroPie/BIOS/mame2015/hiscore.dat"
}

"${@}"
