#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-flycast-next"
rp_module_desc="Multi-platform Sega Dreamcast, Naomi and Atomiswave emulator derived from Reicast"
rp_module_help="Dreamcast ROM Extensions: .cdi .gdi .chd .m3u, Naomi/Atomiswave ROM Extension: .zip\n\nCopy your Dreamcast/Naomi roms to $romdir/dreamcast\n\nCopy the required Dreamcast BIOS file dc_boot.bin to $biosdir/dc\n\nCopy the required Naomi/Atomiswave BIOS files naomi.zip and awbios.zip to $biosdir/dc"
rp_module_licence="GPL2 https://raw.githubusercontent.com/flyinghead/flycast/master/LICENSE"
rp_module_repo="git https://github.com/flyinghead/flycast.git v2.0"
rp_module_section="opt"
rp_module_flags="!armv6"

function depends_lr-flycast-next() {
    local depends=(cmake zlib1g-dev libzip-dev)
    isPlatform "videocore" && depends+=(libraspberrypi-dev)
    isPlatform "mesa" && depends+=(libgles2-mesa-dev)
    isPlatform "x11" && depends+=(libgl-dev)
    getDepends "${depends[@]}"
}

# https://github.com/flyinghead/flycast/commit/8001af97433ef9aff00f71cf55920c43b32e42cd started breaking builds
# on RPI4 32-bit, so we're stuck on v2.0 for now until we figure out what about that commit breaks the build.
function sources_lr-flycast-next() {
    gitPullOrClone
}

function build_lr-flycast-next() {
    local params=("-DLIBRETRO=On -DUSE_HOST_LIBZIP=On -DCMAKE_BUILD_TYPE=Release")
    local add_flags=()
    if isPlatform "gles" && ! isPlatform "gles3" ; then
        if isPlatform "videocore"; then
            add_flags+=("-I/opt/vc/include -DLOW_END")
            params+=("-DUSE_VIDEOCORE=On")
        fi
        params+=("-DUSE_GLES2=On")
    fi

    isPlatform "gles3" && params+=("-DUSE_GLES=On")
    ! isPlatform "x86" && params+=("-DUSE_VULKAN=Off")

    mkdir -p build
    cd build
    CFLAGS="$CFLAGS ${add_flags[@]}" CXXFLAGS="$CXXFLAGS ${add_flags}" cmake "${params[@]}" ..
    make
    md_ret_require="$md_build/build/flycast_libretro.so"
}

function install_lr-flycast-next() {
    md_ret_files=(
        'build/flycast_libretro.so'
        'LICENSE'
        'README.md'
    )
}

function configure_lr-flycast-next() {
    configure_lr-flycast
}
