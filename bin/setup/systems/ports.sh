#!/bin/bash

set -ex

system='ports'
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
. "$dir/../system-common.sh"

install() {
  # Duke 3D
  install_retropie_package 'emulators' eduke32
  ln -fs "$HOME/RetroPie/roms/pc/.exodos/Duke3D/DUKE3D/DUKE3D.GRP" "$HOME/RetroPie/roms/ports/duke3d/duke3d.grp"
  ln -fs "$HOME/RetroPie/roms/pc/.exodos/Duke3D/DUKE3D/DUKE.RTS" "$HOME/RetroPie/roms/ports/duke3d/duke.rts"

  # Quake
  install_retropie_package 'emulators' lr-tyrquake
  ln -fs "$HOME/RetroPie/roms/pc/.exodos/Quake/QUAKE/ID1/PAK1.PAK" "$HOME/RetroPie/roms/ports/quake/id1/pak1.pak"

  # Doom
  install_retropie_package 'emulators' lr-prboom
  ln -fs "$HOME/RetroPie/roms/pc/.exodos/DOOM/DOOM.WAD" "$HOME/RetroPie/roms/ports/doom/doom.wad"
}

uninstall() {
  echo 'No uninstall for ports'
}

"${@}"
