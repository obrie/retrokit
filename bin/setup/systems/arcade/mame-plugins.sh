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
  __build_mame
}

__build_mame2016() {
  if has_libretro_core 'mame2016'; then
    if [ ! -f "$bios_dir/mame2016/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local mame_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
      git clone --depth 1 https://github.com/libretro/mame2016-libretro "$mame_dir"
      rm -rf "$bios_dir/mame2016/plugins"
      cp -Rv "$mame_dir/plugins/" "$bios_dir/mame2016/"
    else
      echo "Already installed plugins (lr-mame2016)"
    fi
  fi
}

__build_mame0222() {
  if has_emulator 'lr-mame0222'; then
    if [ ! -f "$bios_dir/mame0222/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local mame_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
      git clone -b lrmame0222 --depth 1 https://github.com/libretro/mame.git "$mame_dir"
      rm -rf "$bios_dir/mame0222/plugins"
      cp -Rv "$mame_dir/plugins/" "$bios_dir/mame0222/"
    else
      echo "Already installed plugins (lr-mame0222)"
    fi
  fi
}

__build_mame0244() {
  if has_emulator 'lr-mame0244'; then
    if [ ! -f "$bios_dir/mame0244/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local repo_archive_file=$(mktemp -p "$tmp_ephemeral_dir")
      local mame_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
      download "https://github.com/mamedev/mame/archive/ee3942fc824edaf67768c249f2dd57ec3a20f4b5.zip" "$repo_archive_file"
      unzip "$repo_archive_file" "mame-*/plugins/*" -d "$mame_dir"
      rm -rf "$bios_dir/mame0244/plugins"
      cp -Rv "$mame_dir/mame-"*"/plugins/" "$bios_dir/mame0244/"
    else
      echo "Already installed plugins (lr-mame0244)"
    fi
  fi
}

__build_mame() {
  if has_emulator 'lr-mame'; then
    if [ ! -f "$bios_dir/mame/plugins/boot.lua" ] || [ "$FORCE_UPDATE" == 'true' ]; then
      local repo_archive_file=$(mktemp -p "$tmp_ephemeral_dir")
      local mame_dir=$(mktemp -d -p "$tmp_ephemeral_dir")
      download "https://github.com/mamedev/mame/archive/master.zip" "$repo_archive_file"
      unzip "$repo_archive_file" "mame-*/plugins/*" -d "$mame_dir"
      rm -rf "$bios_dir/mame/plugins"
      cp -Rv "$mame_dir/mame-"*"/plugins/" "$bios_dir/mame/"
    else
      echo "Already installed plugins (lr-mame)"
    fi
  fi
}

remove() {
  rm -rfv \
    "$bios_dir/mame2016/plugins/" \
    "$bios_dir/mame0222/plugins/" \
    "$bios_dir/mame0244/plugins/" \
    "$bios_dir/mame/plugins/"
}

setup "${@}"
