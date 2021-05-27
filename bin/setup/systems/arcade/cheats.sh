#!/bin/bash

set -ex

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

has_emulator() {
  if [ $(system_setting ".emulators | has(\"$1\")") == 'true' ]; then
    return 0
  else
    return 1
  fi
}

install() {
  # Cheats: FBNeo
  if has_emulator 'lr-fbneo'; then
    mkdir -p "$HOME/RetroPie/BIOS/fbneo/cheats"
    if [ ! -f "$system_tmp_dir/fbneo-cheats.zip" ]; then
      download 'https://github.com/finalburnneo/FBNeo-cheats/archive/master.zip' "$system_tmp_dir/fbneo-cheats.zip"
      unzip -j "$system_tmp_dir/fbneo-cheats.zip" 'FBNeo-cheats-master/cheats/*' -d "$HOME/RetroPie/BIOS/fbneo/cheats/"
    fi
  fi

  # Cheats: MAME (libretro)
  if has_emulator 'lr-mame2010'; then
    download 'https://github.com/libretro/mame2010-libretro/raw/master/metadata/cheat.zip' "$HOME/RetroPie/BIOS/mame2010/cheat.zip"
  fi

  if has_emulator 'lr-mame2015'; then
    download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/cheat.7z' "$HOME/RetroPie/BIOS/mame2015/cheat.7z"
  fi

  if has_emulator 'lr-mame2016'; then
    download 'https://github.com/libretro/mame2016-libretro/raw/master/metadata/cheat.7z' "$HOME/RetroPie/BIOS/mame2016/cheat.7z"
  fi

  if has_emulator 'advmame'; then
    download 'https://github.com/amadvance/advancemame/raw/master/support/cheat.dat' "$HOME/RetroPie/BIOS/advmame/cheat.dat"
  fi

  # Cheats: MAME (Pugsy)
  if has_emulator 'mame'; then
    if [ ! -f "$system_tmp_dir/mame-cheats.zip" ]; then
      download 'http://cheat.retrogames.com/download/cheat0221.zip' "$system_tmp_dir/mame-cheats.zip"
      unzip -j "$system_tmp_dir/mame-cheats.zip" "cheat.7z" -d "$HOME/RetroPie/BIOS/mame/"
    fi
  fi
}

uninstall() {
  rm -f "$HOME/RetroPie/BIOS/mame/cheats.7z"\
    "$HOME/RetroPie/BIOS/advmame/cheat.dat"\
    "$HOME/RetroPie/BIOS/mame2016/cheat.7z"\
    "$HOME/RetroPie/BIOS/mame2015/cheat.7z"\
    "$HOME/RetroPie/BIOS/mame2010/cheat.zip"
  rm -rf "$HOME/RetroPie/BIOS/fbneo/cheats/"
}

"${@}"
