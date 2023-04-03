#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"
. "$dir/mame-common.sh"

setup_module_id='systems/arcade/mame-history'
setup_module_desc='History DAT support for MAME'

history_dat_url="$binary_base_url/mame-historydat241.zip"

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
  __build_mame0222
  __build_mame0244
  __build_mame
}

__build_mame2003_plus() {
  if has_libretro_core 'mame2003-plus'; then
    ln_if_different "$retropie_dir/libretrocores/lr-mame2003-plus/metadata/history.dat" "$bios_dir/mame2003-plus/history.dat"
  fi
}

__build_mame2016() {
  if has_libretro_core 'mame2016'; then
    if [ ! -f "$bios_dir/mame2016/history/history.dat" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local historydat_file=$(mktemp -p "$tmp_ephemeral_dir")
      download "$history_dat_url" "$historydat_file"

      mkdir -p "$bios_dir/mame2016/history"
      unzip -oj "$historydat_file" -d "$bios_dir/mame2016/history/"
    else
      echo "Already installed history.dat (lr-mame2016)"
    fi
  fi
}

__build_mame0222() {
  if has_emulator 'lr-mame0222'; then
    if [ ! -f "$bios_dir/mame0222/history/history.dat" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local historydat_file=$(mktemp -p "$tmp_ephemeral_dir")
      download "$history_dat_url" "$historydat_file"

      mkdir -p "$bios_dir/mame0222/history"
      unzip -oj "$historydat_file" -d "$bios_dir/mame0222/history/"
    else
      echo "Already installed history.dat (lr-mame0222)"
    fi
  fi
}

__build_mame0244() {
  if has_emulator 'lr-mame0244'; then
    if [ ! -f "$bios_dir/mame0244/history/history.xml" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local historydat_file=$(mktemp -p "$tmp_ephemeral_dir")
      download 'https://www.arcade-history.com/dats/historyxml244.zip' "$historydat_file"

      mkdir -p "$bios_dir/mame0244/history"
      unzip -oj "$historydat_file" -d "$bios_dir/mame0244/history/"
    else
      echo "Already installed history.dat (lr-mame0244)"
    fi
  fi
}

__build_mame() {
  if has_emulator 'lr-mame'; then
    if [ ! -f "$bios_dir/mame/history/history.xml" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local historydat_file=$(mktemp -p "$tmp_ephemeral_dir")
      download "$(__find_latest_mame_support_file historyxml)" "$historydat_file"

      mkdir -p "$bios_dir/mame/history"
      unzip -oj "$historydat_file" -d "$bios_dir/mame/history/"
    else
      echo "Already installed history.dat (lr-mame)"
    fi
  fi
}

remove() {
  rm -fv \
    "$bios_dir/mame2003-plus/history.dat" \
    "$bios_dir/mame2016/history/history.dat" \
    "$bios_dir/mame0222/history/history.dat" \
    "$bios_dir/mame0244/history/history.xml" \
    "$bios_dir/mame/history/history.xml"
}

setup "${@}"
