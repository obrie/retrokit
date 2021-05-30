#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-duckstation-psx"
rp_module_desc="PlayStation emulator - Duckstation PSX for libretro"
rp_module_help="ROM Extensions: .bin .cue .cbn .img .iso .m3u .mdf .pbp .toc .z .znx\n\nCopy your PlayStation roms to $romdir/psx\n\nCopy the required BIOS files\n\nscph5500.bin and\nscph5501.bin and\nscph5502.bin to\n\n$biosdir"
rp_module_licence="GPL3 https://raw.githubusercontent.com/stenzek/duckstation/master/LICENSE"
rp_module_repo="git https://github.com/stenzek/duckstation.git master"
rp_module_section="exp"
rp_module_flags=""

function __binary_url_lr-duckstation-psx() {
    echo "https://www.duckstation.org/libretro/duckstation_libretro_linux_armv7.zip"
}

function install_bin_lr-duckstation-psx() {
    downloadAndExtract "$(__binary_url_lr-duckstation-psx)" "$md_inst"
}

function configure_lr-duckstation-psx() {
    mkRomDir "psx"
    ensureSystemretroconfig "psx"

    addEmulator 0 "$md_id" "psx" "$md_inst/duckstation_libretro.so"
    addSystem "psx"
}
