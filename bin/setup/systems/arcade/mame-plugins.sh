#!/bin/bash

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../../system-common.sh"

setup_module_id='systems/arcade/mame-plugins'
setup_module_desc='Plugins support for MAME 2016 and newer (cheat, hiscore, data, etc.)'

build() {
  __build_mame2016
  __build_mame0222
  __build_mame0244
}

__build_mame2016() {
  if has_emulator 'lr-mame2016'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame2016/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      git clone --depth 1 https://github.com/libretro/mame2016-libretro "$tmp_ephemeral_dir/mame2016-libretro"
      rm -rf "$HOME/RetroPie/BIOS/mame2016/plugins"
      cp -Rv "$tmp_ephemeral_dir/mame2016-libretro/plugins/" "$HOME/RetroPie/BIOS/mame2016/"
    else
      echo "Already installed plugins (lr-mame2016)"
    fi
  fi
}

__build_mame0222() {
  if has_emulator 'lr-mame0222'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame0222/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      git clone -b lrmame0222 --depth 1 https://github.com/libretro/mame.git "$tmp_ephemeral_dir/mame0222-libretro"
      rm -rf "$HOME/RetroPie/BIOS/mame0222/plugins"
      cp -Rv "$tmp_ephemeral_dir/mame0222-libretro/plugins/" "$HOME/RetroPie/BIOS/mame0222/"
    else
      echo "Already installed plugins (lr-mame0222)"
    fi
  fi
}

__build_mame0244() {
  if has_emulator 'lr-mame0244'; then
    if [ ! -f "$HOME/RetroPie/BIOS/mame0244/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      download "https://github.com/mamedev/mame/archive/ee3942fc824edaf67768c249f2dd57ec3a20f4b5.zip" "$tmp_ephemeral_dir/mame0244.zip"
      unzip "$tmp_ephemeral_dir/mame0244.zip" "mame-*/plugins/*" -d "$tmp_ephemeral_dir/mame0244"
      rm -rf "$HOME/RetroPie/BIOS/mame0244/plugins"
      cp -Rv "$tmp_ephemeral_dir/mame0244/mame-"*"/plugins/" "$HOME/RetroPie/BIOS/mame0244/"
    else
      echo "Already installed plugins (lr-mame0244)"
    fi
  fi
}

remove() {
  rm -rfv \
    "$HOME/RetroPie/BIOS/mame2016/plugins/" \
    "$HOME/RetroPie/BIOS/mame0222/plugins/" \
    "$HOME/RetroPie/BIOS/mame0244/plugins/"
}

setup "${@}"
