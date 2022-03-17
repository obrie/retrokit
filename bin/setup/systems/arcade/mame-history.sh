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
    ln -fsv '/opt/retropie/libretrocores/lr-mame2003-plus/metadata/history.dat' "$HOME/RetroPie/BIOS/mame2003-plus/history.dat"
  fi
}

__build_mame2016() {
  if has_emulator 'lr-mame2016'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame2016/history/history.dat" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      download "$history_dat_url" "$tmp_ephemeral_dir/historydat.zip"

      mkdir -p "$HOME/RetroPie/BIOS/mame2016/history"
      unzip -oj "$tmp_ephemeral_dir/historydat.zip" -d "$HOME/RetroPie/BIOS/mame2016/history/"
    else
      echo "Already installed history.dat (lr-mame2016)"
    fi
  fi
}

__build_mame() {
  if has_emulator 'lr-mame'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame/history/history.dat" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      download "$history_dat_url" "$tmp_ephemeral_dir/historydat.zip"

      mkdir -p "$HOME/RetroPie/BIOS/mame/history"
      unzip -oj "$tmp_ephemeral_dir/historydat.zip" -d "$HOME/RetroPie/BIOS/mame/history/"
    else
      echo "Already installed history.dat (lr-mame)"
    fi
  fi
}

remove() {
  rm -fv \
    "$HOME/RetroPie/BIOS/mame2016/history/history.dat" \
    "$HOME/RetroPie/BIOS/mame/history/history.dat"
}

setup "${@}"
