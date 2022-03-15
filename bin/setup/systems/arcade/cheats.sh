#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/cheats'
setup_module_desc='Cheats for Arcade systems'

build() {
  __build_fbneo
  __build_mame2015
  __build_mame2016
  __build_advmame
  __build_mame
}

__build_fbneo() {
  # Cheats: FBNeo
  if has_emulator 'lr-fbneo'; then
    mkdir -p "$HOME/RetroPie/BIOS/fbneo/cheats"
    local url='https://github.com/finalburnneo/FBNeo-cheats/archive/master.zip'

    if [ -z "$(ls -A "$HOME/RetroPie/BIOS/fbneo/cheats/")" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      download "$url" "$tmp_ephemeral_dir/fbneo-cheats.zip"
      unzip -jo "$tmp_ephemeral_dir/fbneo-cheats.zip" 'FBNeo-cheats-master/cheats/*' -d "$HOME/RetroPie/BIOS/fbneo/cheats/"
    else
      echo "Already downloaded $url"
    fi
  fi
}

__build_mame2015() {
  if has_emulator 'lr-mame2015'; then
    download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/cheat.7z' "$HOME/RetroPie/BIOS/mame2015/cheat.7z"
  fi
}

__build_mame2016() {
  if has_emulator 'lr-mame2016'; then
    download 'https://github.com/libretro/mame2016-libretro/raw/master/metadata/cheat.7z' "$HOME/RetroPie/BIOS/mame2016/cheat.7z"
  fi
}

__build_advmame() {
  if has_emulator 'advmame'; then
    download 'https://github.com/amadvance/advancemame/raw/master/support/cheat.dat' "$HOME/RetroPie/BIOS/advmame/cheat.dat"
  fi
}

__build_mame() {
  # Cheats: MAME (Pugsy)
  if has_emulator 'lr-mame'; then
    local url='http://cheat.retrogames.com/download/cheat0221.zip'

    if [ ! -f "$HOME/RetroPie/BIOS/mame/cheat.7z" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      download "$url" "$tmp_ephemeral_dir/mame-cheats.zip"
      unzip -jo "$tmp_ephemeral_dir/mame-cheats.zip" "cheat.7z" -d "$HOME/RetroPie/BIOS/mame/"
    else
      echo "Already downloaded $url"
    fi
  fi
}

remove() {
  rm -fv \
    "$HOME/RetroPie/BIOS/advmame/cheat.dat" \
    "$HOME/RetroPie/BIOS/fbneo/cheats/"\
    "$HOME/RetroPie/BIOS/mame/cheats.7z" \
    "$HOME/RetroPie/BIOS/mame2010/cheat.zip" \
    "$HOME/RetroPie/BIOS/mame2015/cheat.7z" \
    "$HOME/RetroPie/BIOS/mame2016/cheat.7z"
}

setup "${@}"
