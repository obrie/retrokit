#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-mame-common"
rp_module_name="MAME Common"
rp_module_desc="MAME Common"

function depends_lr-mame-common() {
  true
}

function sources_lr-mame-common() {
  true
}

function build_lr-mame-common() {
  true
}

function install_lr-mame-common() {
  true
}

function configure_lr-mame-common() {
  local mame_version=$1

  local retroarch_bin="$rootdir/emulators/retroarch/bin/retroarch"
  local retroarch_config="$configdir/arcade/retroarch.cfg"
  local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
  local script_runner=$(readlink -f "$current_dir/../run_mame.sh")

  local system
  for system in arcade mame-libretro; do
      mkRomDir "$system"
      defaultRAConfig "$system"
      addEmulator 0 "$md_id" "$system" "$script_runner $retroarch_bin $md_inst/mamearcade_libretro.so $mame_version $retroarch_config $biosdir %ROM%"
      addSystem "$system"
  done
}
