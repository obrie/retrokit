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
rp_module_licence="GPL3 https://raw.githubusercontent.com/libretro/duckstation/master/LICENSE"
rp_module_repo="git https://github.com/libretro/duckstation.git master"
rp_module_section="exp"
rp_module_flags=""

function depends_lr-duckstation-psx() {
    local depends=(libvulkan-dev libgl1-mesa-dev )
    getDepends "${depends[@]}"
}

function sources_lr-duckstation-psx() {
    gitPullOrClone
}

function build_lr-duckstation-psx() {
    mkdir build
    cd build
    cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBRETRO_CORE=ON ..
    ninja -t clean
    ninja
    md_ret_require="$md_build/build/duckstation_libretro.so"
}

function install_lr-duckstation-psx() {
    md_ret_files=(
        'build/duckstation_libretro.so'
    )
}

function configure_lr-duckstation-psx() {
    mkRomDir "psx"
    ensureSystemretroconfig "psx"

    addEmulator 0 "$md_id" "psx" "$md_inst/duckstation_libretro.so"
    addSystem "psx"
}
