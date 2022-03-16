#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/cheats'
setup_module_desc='Cheats for Arcade systems'

# The following emulators have their cheats installed automatically by RetroPie:
# * advmame (/opt/retropie/emulators/advmame-joy/share/advance/cheat.dat)
# * lr-mame2003 ($HOME/RetroPie/BIOS/mame2003/cheat.dat)
# * lr-mame2003-plus ($HOME/RetroPie/BIOS/mame2003-plus/cheat.dat)
# 
# Cheats are broken on the following emulators (nothing we can do about it):
# * lr-mame2010
build() {
  __build_fbneo
  __build_mame2015
  __build_mame2016
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
  rm -rfv \
    "$HOME/RetroPie/BIOS/fbneo/cheats/" \
    "$HOME/RetroPie/BIOS/mame/cheats.7z" \
    "$HOME/RetroPie/BIOS/mame2015/cheat.7z" \
    "$HOME/RetroPie/BIOS/mame2016/cheat.7z"
}

setup "${@}"
