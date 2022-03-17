#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-plugins'
setup_module_desc='Plugins support for MAME 2016 and newer (cheat, hiscore, data, etc.)'

build() {
  __build_mame2016
  __build_mame
}

__build_mame2016() {
  if has_emulator 'lr-mame2016'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame2016/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      git clone --depth 1 https://github.com/libretro/mame2016-libretro "$tmp_ephemeral_dir/mame2016-libretro"
      rm -rf "$HOME/RetroPie/BIOS/mame2016/plugins"
      cp -R "$tmp_ephemeral_dir/mame2016-libretro/plugins/" "$HOME/RetroPie/BIOS/mame2016/"
    else
      echo "Already installed plugins (lr-mame2016)"
    fi
  fi
}

__build_mame() {
  if has_emulator 'lr-mame'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      git clone -b lrmame0222 --depth 1 https://github.com/libretro/mame.git "$tmp_ephemeral_dir/mame-libretro"
      rm -rf "$HOME/RetroPie/BIOS/mame/plugins"
      cp -R "$tmp_ephemeral_dir/mame-libretro/plugins/" "$HOME/RetroPie/BIOS/mame/"
    else
      echo "Already installed plugins (lr-mame)"
    fi
  fi
}

remove() {
  rm -rfv \
    "$HOME/RetroPie/BIOS/mame2016/plugins/" \
    "$HOME/RetroPie/BIOS/mame/plugins/"
}

setup "${@}"
