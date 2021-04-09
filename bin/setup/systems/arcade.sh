#!/bin/bash

##############
# System: Arcade
##############

setup_cheats() {
  # Cheats: FBNeo
  mkdir -p "$HOME/RetroPie/BIOS/fbneo/cheats"
  if [ ! -f "$system_tmp_dir/fbneo-cheats.zip" ]
    download_file "https://github.com/finalburnneo/FBNeo-cheats/archive/master.zip" "$system_tmp_dir/fbneo-cheats.zip"
    unzip -j "$system_tmp_dir/fbneo-cheats.zip" "FBNeo-cheats-master/cheats/*" -d "$HOME/RetroPie/BIOS/fbneo/cheats/"
  fi

  # Cheats: MAME (libretro)
  download_file "https://github.com/libretro/mame2010-libretro/raw/master/metadata/cheat.zip" "$HOME/RetroPie/BIOS/mame2010/cheat.zip"
  download_file "https://github.com/libretro/mame2015-libretro/raw/master/metadata/cheat.7z" "$HOME/RetroPie/BIOS/mame2015/cheat.7z"
  download_file "https://github.com/libretro/mame2016-libretro/raw/master/metadata/cheat.7z" "$HOME/RetroPie/BIOS/mame2016/cheat.7z"
  download_file "https://github.com/amadvance/advancemame/raw/master/support/cheat.dat" "$HOME/RetroPie/BIOS/advmame/cheat.dat"

  # Cheats: MAME (Pugsy)
  if [ ! -f "$system_tmp_dir/mame-cheats.zip" ]; then
    download_file "http://cheat.retrogames.com/download/cheat0221.zip" "$system_tmp_dir/mame-cheats.zip"
    unzip -j "$system_tmp_dir/mame-cheats.zip" "cheat.7z" -d "$HOME/RetroPie/BIOS/mame/"
  fi
}

setup_hiscores() {
  # Hiscores: FBNeo (already installed)

  # Hiscores: MAME (pre 2016)
  download_file "https://github.com/libretro/mame2010-libretro/raw/master/metadata/hiscore.dat" "$HOME/RetroPie/BIOS/mame2010/"

  # Hiscores: MAME (post 2016)
  download_file "https://github.com/libretro/mame2015-libretro/raw/master/metadata/hiscore.dat" "$HOME/RetroPie/BIOS/mame2015/"
  download_file "https://github.com/libretro/mame2016-libretro/raw/master/metadata/hiscore.dat" "$HOME/RetroPie/BIOS/mame2016/"
}
