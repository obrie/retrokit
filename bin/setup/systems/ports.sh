#!/bin/bash

set -ex

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  # Duke 3D
  install_retropie_package 'ports' eduke32
  if [ -d "$HOME/RetroPie/roms/pc/.exodos/Duke3D" ]; then
    file_ln "$HOME/RetroPie/roms/pc/.exodos/Duke3D/DUKE3D/DUKE3D.GRP" "$HOME/RetroPie/roms/ports/duke3d/duke3d.grp"
    file_ln "$HOME/RetroPie/roms/pc/.exodos/Duke3D/DUKE3D/DUKE.RTS" "$HOME/RetroPie/roms/ports/duke3d/duke.rts"
  fi

  # Quake
  install_retropie_package 'libretrocores' lr-tyrquake
  if [ -d "$HOME/RetroPie/roms/pc/.exodos/Quake" ]; then
    file_ln "$HOME/RetroPie/roms/pc/.exodos/Quake/QUAKE/ID1/PAK1.PAK" "$HOME/RetroPie/roms/ports/quake/id1/pak1.pak"
  fi

  # Doom
  install_retropie_package 'libretrocores' lr-prboom
  if [ -d "$HOME/RetroPie/roms/pc/.exodos/DOOM" ]; then
    file_ln "$HOME/RetroPie/roms/pc/.exodos/DOOM/DOOM.WAD" "$HOME/RetroPie/roms/ports/doom/doom.wad"
  fi
}

uninstall() {
  echo 'No uninstall for ports'
}

"${@}"
