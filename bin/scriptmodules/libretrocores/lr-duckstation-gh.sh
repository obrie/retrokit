#!/usr/bin/env bash

# This file is part of The RetroPie Project
#
# The RetroPie Project is the legal property of its developers, whose names are
# too numerous to list here. Please refer to the COPYRIGHT.md file distributed with this source.
#
# See the LICENSE.md file at the top-level directory of this distribution and
# at https://raw.githubusercontent.com/RetroPie/RetroPie-Setup/master/LICENSE.md
#

rp_module_id="lr-duckstation-gh"
rp_module_desc="PlayStation emulator - Duckstation for libretro"
rp_module_help="ROM Extensions: .exe .cue .bin .chd .psf .m3u .pbp\n\nCopy your PlayStation roms to $romdir/psx\n\nCopy compatible BIOS files to $biosdir"
rp_module_licence="PROP https://creativecommons.org/licenses/by-nc-nd/4.0"
rp_module_section="exp"
rp_module_flags="!all arm !armv6 aarch64 64bit"

function __binary_url_lr-duckstation-gh() {
    local url="https://github.com/batocera-linux/lr-duckstation/raw/master/duckstation_libretro_linux_"
    isPlatform "aarch64" && echo "${url}aarch64.zip"
    isPlatform "arm" && echo "${url}armv7.zip"
    isPlatform "x86" && isPlatform "64bit" && echo "${url}x64.zip"
}

function install_bin_lr-duckstation-gh() {
    downloadAndExtract "$(__binary_url_lr-duckstation-gh)" "$md_inst"
}

function configure_lr-duckstation-gh() {
    configure_lr-duckstation
}
