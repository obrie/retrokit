#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-mess-jaguar"
rp_module_name="Atari Jaguar"
rp_module_ext=".zip"
rp_module_desc="MESS emulator ($rp_module_name) - MESS Port for libretro"
rp_module_help="Requires lr-mess already installed.\n\nROM Extensions: $rp_module_ext\n\n
Put games in:\n
$romdir/atarijaguar\n\n
Put BIOS files in $biosdir:\n
jaguarboot.zip, jaguar.zip, jaguarcd.zip"
rp_module_licence="GPL2 https://raw.githubusercontent.com/libretro/mame/master/LICENSE.md"
rp_module_section="exp"
rp_module_flags=""

alias depends_lr-mess-jaguar="depends_lr-mess-common"
alias sources_lr-mess-jaguar="sources_lr-mess-common"
alias build_lr-mess-jaguar="build_lr-mess-common"
alias install_lr-mess-jaguar="install_lr-mess-common"

function configure_lr-mess-jaguar() {
  configure_lr-mess-common atarijaguar jaguar "-cart"
}
