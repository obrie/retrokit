#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-history'
setup_module_desc='History DAT support for MAME'

history_dat_url='https://www.arcade-history.com/dats/historydat241.zip'

# The following emulators have their history dats installed automatically by RetroPie:
# * advmame (/opt/retropie/emulators/advmame-joy/share/advance/history.dat)
# 
# The following emulators do not support history files:
# * lr-fbneo
# * lr-mame2003
# * lr-mame2010
# * lr-mame2015
build() {
  __build_mame2003_plus
  __build_mame2016
  __build_mame
}

__build_mame2003_plus() {
  if has_emulator 'lr-mame2003-plus'; then
    download 'https://github.com/libretro/mame2003-plus-libretro/blob/master/metadata/history.dat' "$HOME/RetroPie/BIOS/mame2003-plus/history.dat"
  fi
}

__build_mame2016() {
  if has_emulator 'lr-mame2016'; then
    download "$history_dat_url" "$tmp_ephemeral_dir/historydat.zip"

    mkdir -p "$HOME/RetroPie/BIOS/mame2016/history"
    unzip -q -j "$tmp_ephemeral_dir/historydat.zip" -d "$HOME/RetroPie/BIOS/mame2016/history/"
  fi
}

__build_mame() {
  if has_emulator 'lr-mame'; then
    download "$history_dat_url" "$tmp_ephemeral_dir/historydat.zip"

    mkdir -p "$HOME/RetroPie/BIOS/mame/history"
    unzip -q -j "$tmp_ephemeral_dir/historydat.zip" "$HOME/RetroPie/BIOS/mame/history/"
  fi
}

remove() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame2016/history/history.dat" \
    "$HOME/RetroPie/BIOS/mame/history/history.dat"
}

setup "${@}"
