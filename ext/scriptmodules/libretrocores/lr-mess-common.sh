#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-mess-common"
rp_module_name="MESS Common"
rp_module_desc="MESS Common"

function depends_lr-mess-common() {
  local _mess=$(dirname "$md_inst")/lr-mess/mamemess_libretro.so
  if [[ ! -f "$_mess" ]]; then
    printMsgs dialog "cannot find '$_mess' !\n\nplease install 'lr-mess' package."
    exit 1
  fi
}

function sources_lr-mess-common() {
  true
}

function build_lr-mess-common() {
  true
}

function install_lr-mess-common() {
  true
}

function configure_lr-mess-common() {
  local system_name=${1:-mess}
  local mess_id=${2:-mame}
  local mess_args=$3

  local md_common_data="${__mod_info[lr-mess-common/path]%/*}/lr-mess-common"
  cp "$md_common_data/run_mess.sh" "$md_inst/"
  chmod +x "$md_inst/run_mess.sh"

  local mess_lib=$(dirname "$md_inst")/lr-mess/mamemess_libretro.so
  local retroarch_bin="$rootdir/emulators/retroarch/bin/retroarch"
  local retroarch_config="$configdir/$system_name/retroarch.cfg"
  local current_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
  local script_runner="$md_inst/run_mess.sh"

  mkRomDir "$system_name"
  ensureSystemretroconfig "$system_name"

  addEmulator 1 "lr-mess-$mess_id" "$system_name" "$script_runner $retroarch_bin $mess_lib $retroarch_config $mess_id $biosdir $(printf '%q' "$mess_args") %ROM%"

  addSystem "$system_name"
}
