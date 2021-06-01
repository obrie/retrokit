#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="yabasanshiro"
rp_module_desc="Saturn emulator"
rp_module_help="ROM Extensions: .bin .chd .cue .iso .mdf\n\nCopy your Sega Saturn roms to $romdir/saturn\n\nCopy the required BIOS file saturn_bios.bin to $biosdir"
rp_module_licence="GPL2 https://raw.githubusercontent.com/devmiyax/yabause/master/LICENSE"
rp_module_repo="git https://github.com/devmiyax/yabause.git pi4"
rp_module_section="exp"
rp_module_flags="!all rpi4"

function depends_yabasanshiro() {
    getDepends git python-pip cmake build-essential protobuf-compiler libprotobuf-dev libsecret-1-dev libssl-dev libsdl2-dev libboost-all-dev
}

function sources_yabasanshiro() {
    gitPullOrClone
}

function build_yabasanshiro() {
    cd "$md_build/yabause"
    git submodule update --init --recursive
    cmake . -DGIT_EXECUTABLE=/usr/bin/git -DYAB_PORTS=retro_arena -DYAB_WANT_DYNAREC_DEVMIYAX=ON -DYAB_WANT_ARM7=ON -DCMAKE_TOOLCHAIN_FILE=../yabause/src/retro_arena/pi4.cmake -DCMAKE_INSTALL_PREFIX="$md_inst"
    make

    md_ret_require=(
        "$md_build/yabause/src/retro_arena/yabasanshiro"
    )
}

function install_yabasanshiro() {
    cd "$md_build/yabause"
    sudo make install
}

function configure_yabasanshiro() {
    mkRomDir "saturn"
    
    addEmulator 0 "$md_id" "saturn" "$md_inst/yabasanshiro -b \"$romdir/saturn/yabasanshiro/saturn_bios.bin\" -i \"%ROM_RAW%\""
    addSystem "saturn"
}
