#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-hiscores'
setup_module_desc='Hiscore support for MAME'

# The following emulators have their hiscores installed automatically by RetroPie:
# * advmame (/opt/retropie/emulators/advmame-joy/share/advance/hiscore.dat)
# * lr-mame2003 ($HOME/RetroPie/BIOS/mame2003/hiscore.dat)
# * lr-mame2003-plus ($HOME/RetroPie/BIOS/mame2003-plus/hiscore.dat)
# * lr-fbneo ($HOME/RetroPie/BIOS/fbneo/hiscore.dat)
# 
# The following emulators have their hiscores installed in the plugins directory:
# * lr-mame2016 ($HOME/RetroPie/BIOS/mame2016/plugins/hiscore/hiscore.dat)
# * lr-mame ($HOME/RetroPie/BIOS/mame/plugins/hiscore/hiscore.dat)
build() {
  __build_mame2010
  __build_mame2015
}

__build_mame2010() {
  if has_emulator 'lr-mame2010'; then
    download 'https://github.com/libretro/mame2010-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2010/hiscore.dat"
  fi
}

__build_mame2015() {
  if has_emulator 'lr-mame2015'; then
    download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2015/hiscore.dat"
  fi
}

configure() {
  __configure_mame
}

__configure_mame() {
  file_cp '{system_config_dir}/mame/hiscore.ini' "$HOME/RetroPie/BIOS/mame/ini/hiscore.ini" backup=false
}

restore() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame/ini/hiscore.ini"
}

remove() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame2010/hiscore.dat" \
    "$HOME/RetroPie/BIOS/mame2015/hiscore.dat"
}

setup "${@}"
