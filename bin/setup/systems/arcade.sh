#!/bin/bash

set -ex

system='arcade'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install_cheats() {
  # Cheats: FBNeo
  mkdir -p "$HOME/RetroPie/BIOS/fbneo/cheats"
  if [ ! -f "$system_tmp_dir/fbneo-cheats.zip" ]; then
    download 'https://github.com/finalburnneo/FBNeo-cheats/archive/master.zip' "$system_tmp_dir/fbneo-cheats.zip"
    unzip -j "$system_tmp_dir/fbneo-cheats.zip" 'FBNeo-cheats-master/cheats/*' -d "$HOME/RetroPie/BIOS/fbneo/cheats/"
  fi

  # Cheats: MAME (libretro)
  download 'https://github.com/libretro/mame2010-libretro/raw/master/metadata/cheat.zip' "$HOME/RetroPie/BIOS/mame2010/cheat.zip"
  download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/cheat.7z' "$HOME/RetroPie/BIOS/mame2015/cheat.7z"
  download 'https://github.com/libretro/mame2016-libretro/raw/master/metadata/cheat.7z' "$HOME/RetroPie/BIOS/mame2016/cheat.7z"
  download 'https://github.com/amadvance/advancemame/raw/master/support/cheat.dat' "$HOME/RetroPie/BIOS/advmame/cheat.dat"

  # Cheats: MAME (Pugsy)
  if [ ! -f "$system_tmp_dir/mame-cheats.zip" ]; then
    download 'http://cheat.retrogames.com/download/cheat0221.zip' "$system_tmp_dir/mame-cheats.zip"
    unzip -j "$system_tmp_dir/mame-cheats.zip" "cheat.7z" -d "$HOME/RetroPie/BIOS/mame/"
  fi
}

install_hiscores() {
  # Hiscores: FBNeo (already installed)

  # Hiscores: MAME (pre 2016)
  download 'https://github.com/libretro/mame2010-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2010/"

  # Hiscores: MAME (post 2016)
  download 'https://github.com/libretro/mame2015-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2015/"
  download 'https://github.com/libretro/mame2016-libretro/raw/master/metadata/hiscore.dat' "$HOME/RetroPie/BIOS/mame2016/"
}

install_advmame_config() {
  local config_path='/opt/retropie/configs/mame-advmame/advmame.rc'
  backup_and_restore "$config_path"

  while IFS="$tab" read -r name value; do
    if [ -z "$name" ]; then
      continue
    fi

    local escaped_name=$(printf '%s\n' "$name" | sed 's/[.[\*^$]/\\&/g')

    sed -i "/$escaped_name /d" "$config_path"
    echo "$name $value" >> "$config_path"
  done < "$system_config_dir/advmame.rc"

  sort -o "$config_path" "$config_path"
}

fix_runahead() {
  local config_dir='/opt/retropie/configs/all/retroarch/config/MAME 2015'
  mkdir -p "$config_dir"

  # MAME 2015 crashes with runahead -- disable it for games running it
  while read -r mod hard_links owner group size month day time filename; do
    local name=$(basename "$filename" .zip)
    local config_path="$config_dir/$name.cfg"

    crudini --set "$config_path" '' run_ahead_enabled false
  done < <(ls -l "$HOME/RetroPie/roms/arcade/-ALL-" | grep 2015)
}

install() {
  install_cheats
  install_hiscores
  install_advmame_config
  fix_runahead
}

uninstall() {
  echo 'No uninstall for arcade'
}

"${@}"
